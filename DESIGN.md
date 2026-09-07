# Desain Teknis - Bel Sekolah Otomatis

## 1. Keputusan Teknologi

State management: flutter_riverpod (v2).
Alasan: compile-safe, tidak bergantung BuildContext, mendukung auto-dispose, dan punya FutureProvider/StreamProvider yang cocok untuk countdown bel berikutnya dan list jadwal dari database.

Penyimpanan:
- sqflite untuk tabel jadwal (query per hari dan sorting waktu mudah).
- shared_preferences untuk pengaturan global (mode senyap, tanggal libur, default bel manual) karena hanya key-value sederhana dan harus cepat dibaca dari background isolate.

Audio: audioplayers.
Alasan: API sederhana (AssetSource, DeviceFileSource), cukup stabil untuk play berulang, dan bisa dipakai dari background isolate.

Penjadwalan: android_alarm_manager_plus + flutter_local_notifications + timezone + permission_handler.
Alasan: Timer/Dart isolate biasa dimatikan sistem saat idle. AlarmManager dengan exact alarm tetap dibangunkan oleh sistem.

## 2. Struktur Folder

lib/
  main.dart                  Bootstrap, init database, notifikasi, alarm, Riverpod scope
  models/
    jadwal_bel.dart          Model JadwalBel + serialisasi Map untuk sqflite
    pengaturan.dart          Model Pengaturan (mode senyap, tanggal libur, default manual)
  services/
    database_service.dart    CRUD SQLite, singleton
    audio_service.dart       Play/stop dengan pengulangan dan jeda
    scheduler_service.dart   Hitung jadwal berikutnya, register/cancel alarm
    notification_service.dart Inisialisasi notifikasi dan channel
    permission_service.dart  Minta izin notifikasi, exact alarm, battery exemption
    file_sound_service.dart  Copy file custom ke direktori aplikasi
  providers/
    jadwal_provider.dart     StateNotifier list jadwal + operasi CRUD/duplikat/toggle
    pengaturan_provider.dart StateNotifier pengaturan global
    countdown_provider.dart  StreamProvider hitung mundur ke bel berikutnya
  screens/
    dashboard_screen.dart    Beranda: countdown, jadwal hari ini, bel manual
    jadwal_list_screen.dart  Daftar semua jadwal + aksi duplikat/hapus/toggle
    jadwal_form_screen.dart  Form tambah/edit + preview suara
    pengaturan_screen.dart   Mode senyap, tanggal libur, default manual, izin
  widgets/
    jadwal_tile.dart         Baris jadwal dengan toggle dan menu aksi
    hari_picker.dart         Checkbox Senin-Minggu
    countdown_card.dart      Kartu hitung mundur bel berikutnya
    bel_manual_button.dart   Tombol besar bunyikan bel manual
  utils/
    waktu.dart               Format jam, hitung selisih, konversi hari
    konstanta.dart           Nama hari, path suara bawaan, channel notifikasi

assets/sounds/
  bel_klasik.wav
  bel_digital.wav
  bel_panjang.wav

## 3. Model Data

JadwalBel:
  id: String
  nama: String
  jam: int
  menit: int
  daftarHari: List<int> (1-7)
  jumlahPengulangan: int (default 3)
  jedaDetik: int (default 5)
  pathSuara: String (misal "assets:bel_klasik.mp3" atau "file:/data/....mp3")
  volume: double (0.0-1.0, default 1.0)
  aktif: bool (default true)

Tabel SQLite jadwal:
  id TEXT PRIMARY KEY, nama TEXT, jam INTEGER, menit INTEGER,
  daftarHari TEXT (csv "1,2,3,4,5"), pengulangan INTEGER,
  jedaDetik INTEGER, pathSuara TEXT, volume REAL, aktif INTEGER (0/1)

Pengaturan (SharedPreferences):
  modeSenyap: bool
  tanggalLibur: List<String> ["2026-06-01", ...]
  manualSuara: String
  manualVolume: double

## 4. Alur Penjadwalan Background

1. Setiap perubahan data (tambah/edit/hapus/toggle/pengaturan), panggil SchedulerService.rescheduleAll().
2. rescheduleAll() membaca semua jadwal aktif, saring yang berlaku untuk 7 hari ke depan (cocokkan daftarHari, lewati tanggal libur, lewati jam yang sudah lewat hari ini kecuali mode debug).
3. Untuk tiap kemunculan, daftarkan one-shot alarm via AndroidAlarmManager.oneShotAt() dengan ID unik (hash dari id jadwal + tanggal). Payload hanya berisi id jadwal (data lengkap dibaca ulang dari DB di dalam callback agar tidak basi).
4. Callback static alarmCallback(id) berjalan di background isolate: init database minimal, baca jadwal by id, cek mode senyap dan tanggal libur, tampilkan notifikasi, putar suara via AudioService.playLoop().
5. Setelah callback selesai, jadwalkan ulang kemunculan berikutnya untuk jadwal tersebut.

Cara kerja di Android agar tetap akurat saat HP di-lock:
- Dipakai setExactAndAllowWhileIdle (via android_alarm_manager_plus exact=true, allowWhileIdle=true), sehingga alarm dilepas dari Doze.
- Aplikasi meminta SCHEDULE_EXACT_ALARM dan USE_EXACT_ALARM di manifest, plus REQUEST_IGNORE_BATTERY_OPTIMIZATIONS agar tidak dibunuh OEM.
- Notifikasi foreground ditampilkan tiap bel berbunyi agar eksekusi terlihat di system tray.

## 5. Desain UI

Prinsip: simpel dan profesional untuk operator sekolah. Satu tema terang, kontras cukup untuk dilihat di luar ruangan.

- Warna: primary biru navy #1A3A5F, aksen hijau #2E7D32 untuk status aktif, merah #C62828 untuk hapus/nonaktif, background abu terang #F4F6F8, teks utama #1A1A1A.
- Font: bawaan Material (Roboto), tanpa font custom agar APK kecil.
- Navigasi: BottomNavigationBar 3 tab (Beranda, Jadwal, Pengaturan). Form tambah/edit sebagai halaman full-screen terpisah.
- Dashboard: kartu atas berisi bel berikutnya + countdown besar, di bawahnya list jadwal hari ini urut waktu. Tombol bel manual berupa tombol lebar di bawah, bukan floating, agar tidak tertekan tidak sengaja.
- Form jadwal: field nama, time picker jam:menit, HariPicker (7 chip Senin-Minggu), stepper pengulangan, stepper jeda, dropdown suara + tombol pilih file, slider volume, tombol preview/stop, switch aktif.

## 6. Izin Android (AndroidManifest)

- POST_NOTIFICATIONS
- SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM
- RECEIVE_BOOT_COMPLETED (jadwal ulang setelah restart)
- WAKE_LOCK
- REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
- READ_EXTERNAL_STORAGE / READ_MEDIA_AUDIO (untuk file picker di Android lama/baru)
- Receiver BootReceiver untuk reschedule setelah boot selesai.
