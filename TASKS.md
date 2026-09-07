# TASKS - Bel Sekolah Otomatis

Urutan pengerjaan bertahap. Setiap tahap selesai hanya lanjut setelah konfirmasi.

## Tahap 0 - Dokumen (selesai)

- [x] PRD.md
- [x] DESIGN.md
- [x] TASKS.md
- [ ] Konfirmasi pubspec.yaml dan struktur folder

## Tahap 1 - Fondasi Project

1. Finalisasi pubspec.yaml (tambah path_provider untuk copy file suara custom).
2. Tambah 3 file suara bawaan ke assets/sounds.
3. Konfigurasi AndroidManifest (izin exact alarm, notifikasi, boot receiver, battery exemption).
4. File utils: konstanta.dart, waktu.dart.

## Tahap 2 - Data Layer

5. models/jadwal_bel.dart (fromMap, toMap, copyWith, validasi).
6. models/pengaturan.dart.
7. services/database_service.dart (init, CRUD, getJadwalHariIni).
8. Verifikasi: flutter analyze.

## Tahap 3 - Service Audio dan Sistem

9. services/audio_service.dart (play dengan pengulangan + jeda + stop, dukung AssetSource dan DeviceFileSource).
10. services/notification_service.dart (init channel, tampilkan notifikasi bel).
11. services/permission_service.dart (notifikasi, exact alarm, battery).
12. services/file_sound_service.dart (pick dan copy file ke app dir).
13. services/scheduler_service.dart (rescheduleAll + alarmCallback static).

## Tahap 4 - State Management

14. providers/jadwal_provider.dart.
15. providers/pengaturan_provider.dart.
16. providers/countdown_provider.dart.

## Tahap 5 - UI

17. widgets: jadwal_tile, hari_picker, countdown_card, bel_manual_button.
18. screens/dashboard_screen.
19. screens/jadwal_list_screen.
20. screens/jadwal_form_screen (dengan preview suara).
21. screens/pengaturan_screen.
22. main.dart final (init semua service + routing bottom nav).

## Tahap 6 - Integrasi dan Uji

23. Uji reschedule tiap CRUD.
24. Uji skenario: mode senyap, tanggal libur, Jumat beda jam, duplikat jadwal.
25. Uji background: kunci layar, minimasi 10 menit sebelum jadwal.
26. flutter analyze + flutter test, perbaiki warning.

Catatan: mulai Tahap 1 hanya setelah struktur dan pubspec disetujui.
