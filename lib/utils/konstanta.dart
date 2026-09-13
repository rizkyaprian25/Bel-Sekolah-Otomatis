// Konstanta global aplikasi Bel Sekolah Otomatis.

class AppKonstanta {
  AppKonstanta._();

  // Warna utama (dipakai di Theme, lihat main.dart Tahap 5).
  static const int navy = 0xFF1A3A5F;
  static const int hijauAktif = 0xFF2E7D32;
  static const int merahNonaktif = 0xFFC62828;
  static const int bgAbu = 0xFFF4F6F8;

  // Nama hari, index 1-7 (1 = Senin) mengikuti DateTime.weekday.
  static const List<String> namaHari = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> namaHariSingkat = [
    '',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  // Suara bawaan. Format path "assets:namafile" agar gampang dibedakan
  // dari file custom ("file:/path/ke/file.mp3").
  static const List<SuaraBawaan> suaraBawaan = [
    // Suara AI Sekolah
    SuaraBawaan(
      id: 'assets:ai_masuk_jp1.mp3',
      label: 'AI: Masuk Jam Ke-1 (Masuk Kelas)',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_2.mp3',
      label: 'AI: Memasuki Jam Ke-2',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_3.mp3',
      label: 'AI: Memasuki Jam Ke-3',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_4.mp3',
      label: 'AI: Memasuki Jam Ke-4',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_5.mp3',
      label: 'AI: Memasuki Jam Ke-5',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_6.mp3',
      label: 'AI: Memasuki Jam Ke-6',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_7.mp3',
      label: 'AI: Memasuki Jam Ke-7',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_8.mp3',
      label: 'AI: Memasuki Jam Ke-8',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_9.mp3',
      label: 'AI: Memasuki Jam Ke-9',
    ),
    SuaraBawaan(
      id: 'assets:ai_jam_ke_10.mp3',
      label: 'AI: Memasuki Jam Ke-10',
    ),
    SuaraBawaan(
      id: 'assets:ai_istirahat.mp3',
      label: 'AI: Waktunya Istirahat',
    ),
    SuaraBawaan(
      id: 'assets:ai_istirahat2_mbg.mp3',
      label: 'AI: Istirahat Ke-2 (Pengambilan MBG)',
    ),
    SuaraBawaan(
      id: 'assets:ai_mbg_jumat.mp3',
      label: 'AI: Pengambilan MBG Jumat (Jam 11)',
    ),
    SuaraBawaan(
      id: 'assets:ai_selesai_istirahat_jp5.mp3',
      label: 'AI: Selesai Istirahat (Masuk JP 5)',
    ),
    SuaraBawaan(
      id: 'assets:ai_selesai_istirahat_umum.mp3',
      label: 'AI: Selesai Istirahat (Masuk Kelas)',
    ),
    SuaraBawaan(
      id: 'assets:ai_pulang.mp3',
      label: 'AI: Waktunya Pulang',
    ),

    // Nada Bel Klasik & Digital
    SuaraBawaan(id: 'assets:bel_klasik.wav', label: 'Nada: Bel Klasik'),
    SuaraBawaan(id: 'assets:bel_digital.wav', label: 'Nada: Bel Digital'),
    SuaraBawaan(id: 'assets:bel_panjang.wav', label: 'Nada: Bel Panjang'),
  ];

  // Notifikasi.
  static const String notifChannelId = 'bel_sekolah_channel';
  static const String notifChannelName = 'Bel Sekolah';
  static const String notifChannelDesc = 'Notifikasi saat bel berbunyi';

  // SharedPreferences keys.
  static const String keyModeSenyap = 'mode_senyap';
  static const String keyTanggalLibur = 'tanggal_libur';
  static const String keyManualSuara = 'manual_suara';
  static const String keyManualVolume = 'manual_volume';
  static const String keyIzinDiminta = 'izin_awal_diminta';

  // Batas validasi.
  static const int minPengulangan = 1;
  static const int maxPengulangan = 20;
  static const int minJedaDetik = 0;
  static const int maxJedaDetik = 60;
}

class SuaraBawaan {
  final String id;
  final String label;
  const SuaraBawaan({required this.id, required this.label});

  /// Nama file saja, misal "bel_klasik.wav".
  String get assetFileName => id.replaceFirst('assets:', '');

  /// Path untuk AudioPlayers AssetSource, misal "sounds/bel_klasik.wav".
  String get assetSourcePath => 'sounds/$assetFileName';
}
