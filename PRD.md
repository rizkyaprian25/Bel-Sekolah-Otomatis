# PRD - Bel Sekolah Otomatis

Versi: 1.0 (Draft)
Tanggal: 2026-09-07
Platform: Android (MVP). iOS tidak termasuk target rilis pertama.

## 1. Latar Belakang dan Tujuan

Sekolah membutuhkan bel yang berbunyi tepat waktu sesuai jadwal pelajaran tanpa operator menekan tombol manual setiap jam. Aplikasi ini dipasang di satu HP Android khusus operator yang diletakkan di ruang TU / dekat pengeras suara, lalu memutar suara bel secara otomatis sesuai jadwal.

Tujuan utama: bel berbunyi akurat walau aplikasi diminimize atau HP terkunci.

## 2. Pengguna

Admin / operator sekolah. Satu peran saja. Tidak ada login, tidak ada multi-user, tidak ada backend.

## 3. Fitur dan Kebutuhan

### F1. Manajemen Jadwal Bel (CRUD)

Setiap jadwal memiliki:
- id (String, uuid)
- nama (misal: Bel Masuk, Bel Istirahat, Bel Pulang)
- jam (0-23), menit (0-59)
- daftarHari (List int 1-7, 1 = Senin, 7 = Minggu)
- jumlahPengulangan (int, minimal 1)
- jedaDetik (int, jeda antar pengulangan, 0 berarti tanpa jeda)
- pathSuara (String: id suara bawaan atau path file custom)
- volume (double 0.0 - 1.0)
- aktif (bool)

Operasi yang harus didukung:
- Tambah, edit, hapus, aktif/nonaktif per jadwal.
- Duplikat jadwal (menyalin semua field kecuali id, nama ditambah suffix " (Salinan)").
- Validasi: nama tidak kosong, jam/menit valid, minimal satu hari dipilih, pengulangan >= 1, jeda >= 0.

Kriteria diterima:
- Jadwal tersimpan permanen di database lokal dan tetap ada setelah restart HP.
- Jadwal berbeda per hari dimodelkan sebagai entri terpisah (misal Pulang Senin-Kamis 15:00, Pulang Jumat 11:30).

### F2. Pengulangan dan Preview Suara

- Input jumlah pengulangan berupa angka bebas (contoh 1, 3, 5).
- Input jeda antar pengulangan dalam detik.
- Tombol preview di form tambah/edit memutar suara sesuai pengulangan dan jeda yang diisi, dengan tombol stop.

### F3. Pilihan Suara

- Minimal 3 suara bawaan di folder assets/sounds (misal bel_klasik.mp3, bel_digital.mp3, bel_panjang.mp3). File aktual disediakan sekolah atau ditambahkan sebelum build.
- Pengguna bisa memilih file mp3/wav dari penyimpanan via file picker. File custom disalin ke direktori aplikasi agar tetap bisa diputar setelah restart.
- Pengaturan volume per jadwal (slider 0-100).

### F4. Eksekusi Background

- Bel harus berbunyi pada jam yang dijadwalkan walau aplikasi ditutup/minimize atau layar terkunci.
- Pendekatan: android_alarm_manager_plus untuk penjadwalan exact satu-shot per jadwal, flutter_local_notifications untuk notifikasi "Bel berbunyi: [nama]", audioplayers untuk memutar suara di callback background.
- Setiap ada perubahan jadwal, semua alarm di-reschedule ulang.
- Saat pertama dibuka, aplikasi meminta: izin notifikasi, izin exact alarm (Alarms and Reminders, Android 12+), dan pengecualian battery optimization. Jika ditolak, tampilkan penjelasan dan tombol buka pengaturan.

Kriteria diterima:
- Uji manual: kunci layar 10 menit sebelum jadwal, bel tetap berbunyi dalam toleransi 1 menit.

### F5. Dashboard / Beranda

Menampilkan:
- Daftar jadwal hari ini urut waktu, dengan penanda sudah lewat / berikutnya.
- Hitung mundur ke bel berikutnya (format HH:MM:SS, update tiap detik).
- Toggle aktif/nonaktif langsung dari daftar.
- Tombol Bel Manual: memutar suara default kapan saja (untuk darurat/upacara). Bel manual memakai konfigurasi suara dan volume yang dipilih di Pengaturan.

### F6. Pengaturan Umum

- Mode senyap global (satu switch): jika aktif, semua bel otomatis dinonaktifkan sementara tanpa menghapus jadwal.
- Daftar tanggal pengecualian (libur/ujian): list tanggal YYYY-MM-DD yang bisa ditambah/hapus. Pada tanggal tersebut tidak ada bel yang berbunyi.
- Pengaturan default bel manual: pilihan suara dan volume.
- Disimpan di SharedPreferences agar ringan dan cepat dibaca oleh callback background.

## 4. Kebutuhan Non-Fungsional

- Akurasi waktu: mengandalkan jam sistem Android. Zona waktu Asia/Jakarta.
- Baterai: HP disarankan selalu terhubung charger dan mode Doze dikecualikan untuk aplikasi ini.
- Penyimpanan: seluruhnya lokal. SQLite (sqflite) untuk jadwal, SharedPreferences untuk pengaturan global.
- Performa: cold start di bawah 2 detik untuk 100 jadwal.

## 5. Batasan dan Asumsi

- MVP Android saja, minimum SDK 23, target SDK 34.
- Tidak ada sinkronisasi antar device atau web dashboard.
- Suara hanya dari speaker HP (atau speaker eksternal via kabel AUX/Bluetooth yang tersambung ke HP tersebut).
- Jika HP mati total atau baterai habis, bel tidak berbunyi. Di luar lingkup aplikasi.

## 6. Di Luar Lingkup (Tidak Dikerjakan di MVP)

- Login, multi-sekolah, cloud backup.
- Jadwal otomatis mengikuti kalender akademik nasional.
- Widget homescreen dan integrasi smart speaker.
