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
    SuaraBawaan(id: 'assets:bel_klasik.wav', label: 'Bel Klasik'),
    SuaraBawaan(id: 'assets:bel_digital.wav', label: 'Bel Digital'),
    SuaraBawaan(id: 'assets:bel_panjang.wav', label: 'Bel Panjang'),
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
