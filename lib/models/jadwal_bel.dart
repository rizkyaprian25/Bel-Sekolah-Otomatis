import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';
import 'package:uuid/uuid.dart';

// Model satu jadwal bel.
// daftarHari memakai 1-7 (1 = Senin) mengikuti DateTime.weekday.
class JadwalBel {
  final String id;
  final String nama;
  final int jam;
  final int menit;
  final List<int> daftarHari;
  final int jumlahPengulangan;
  final int jedaDetik;
  final String pathSuara;
  final double volume;
  final bool aktif;

  const JadwalBel({
    required this.id,
    required this.nama,
    required this.jam,
    required this.menit,
    required this.daftarHari,
    this.jumlahPengulangan = 3,
    this.jedaDetik = 5,
    required this.pathSuara,
    this.volume = 1.0,
    this.aktif = true,
  });

  factory JadwalBel.baru({
    required String nama,
    required int jam,
    required int menit,
    required List<int> daftarHari,
    int jumlahPengulangan = 3,
    int jedaDetik = 5,
    required String pathSuara,
    double volume = 1.0,
  }) {
    return JadwalBel(
      id: const Uuid().v4(),
      nama: nama.trim(),
      jam: jam,
      menit: menit,
      daftarHari: List.of(daftarHari)..sort(),
      jumlahPengulangan: jumlahPengulangan,
      jedaDetik: jedaDetik,
      pathSuara: pathSuara,
      volume: volume,
      aktif: true,
    );
  }

  JadwalBel copyWith({
    String? nama,
    int? jam,
    int? menit,
    List<int>? daftarHari,
    int? jumlahPengulangan,
    int? jedaDetik,
    String? pathSuara,
    double? volume,
    bool? aktif,
  }) {
    return JadwalBel(
      id: id,
      nama: nama ?? this.nama,
      jam: jam ?? this.jam,
      menit: menit ?? this.menit,
      daftarHari: daftarHari ?? List.of(this.daftarHari),
      jumlahPengulangan: jumlahPengulangan ?? this.jumlahPengulangan,
      jedaDetik: jedaDetik ?? this.jedaDetik,
      pathSuara: pathSuara ?? this.pathSuara,
      volume: volume ?? this.volume,
      aktif: aktif ?? this.aktif,
    );
  }

  /// Buat salinan untuk fitur duplikat. ID baru, nama diberi suffix.
  JadwalBel duplikat() {
    return JadwalBel(
      id: const Uuid().v4(),
      nama: '$nama (Salinan)',
      jam: jam,
      menit: menit,
      daftarHari: List.of(daftarHari),
      jumlahPengulangan: jumlahPengulangan,
      jedaDetik: jedaDetik,
      pathSuara: pathSuara,
      volume: volume,
      aktif: false,
    );
  }

  /// Validasi. Return null jika valid, atau pesan error jika tidak.
  String? validasi() {
    if (nama.trim().isEmpty) return 'Nama jadwal tidak boleh kosong';
    if (jam < 0 || jam > 23) return 'Jam harus 0-23';
    if (menit < 0 || menit > 59) return 'Menit harus 0-59';
    if (daftarHari.isEmpty) return 'Pilih minimal satu hari';
    if (daftarHari.any((h) => h < 1 || h > 7)) {
      return 'Hari tidak valid';
    }
    if (jumlahPengulangan < AppKonstanta.minPengulangan ||
        jumlahPengulangan > AppKonstanta.maxPengulangan) {
      return 'Pengulangan harus ${AppKonstanta.minPengulangan}-${AppKonstanta.maxPengulangan}';
    }
    if (jedaDetik < AppKonstanta.minJedaDetik ||
        jedaDetik > AppKonstanta.maxJedaDetik) {
      return 'Jeda harus ${AppKonstanta.minJedaDetik}-${AppKonstanta.maxJedaDetik} detik';
    }
    if (pathSuara.isEmpty) return 'Pilih suara bel';
    if (volume < 0 || volume > 1) return 'Volume harus 0-100';
    return null;
  }

  String get jamLabel => formatJamMenit(jam, menit);

  String get hariLabel {
    if (daftarHari.length == 7) return 'Setiap hari';
    if (_sama([1, 2, 3, 4, 5])) return 'Senin-Jumat';
    if (_sama([1, 2, 3, 4, 5, 6])) return 'Senin-Sabtu';
    final s = List.of(daftarHari)..sort();
    return s.map((h) => AppKonstanta.namaHariSingkat[h]).join(', ');
  }

  bool _sama(List<int> lain) {
    if (daftarHari.length != lain.length) return false;
    final a = List.of(daftarHari)..sort();
    final b = List.of(lain)..sort();
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// True jika jadwal ini berbunyi pada [tanggal] (cek hari saja,
  /// belum termasuk tanggal libur / mode senyap).
  bool berlakuPada(DateTime tanggal) {
    return daftarHari.contains(tanggal.weekday);
  }

  bool get isSuaraAsset => pathSuara.startsWith('assets:');

  // --- Serialisasi SQLite ---

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jam': jam,
      'menit': menit,
      'daftarHari': daftarHari.join(','),
      'pengulangan': jumlahPengulangan,
      'jedaDetik': jedaDetik,
      'pathSuara': pathSuara,
      'volume': volume,
      'aktif': aktif ? 1 : 0,
    };
  }

  factory JadwalBel.fromMap(Map<String, Object?> map) {
    final hariRaw = (map['daftarHari'] as String?) ?? '';
    final hari = hariRaw.isEmpty
        ? <int>[]
        : hariRaw
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((h) => h >= 1 && h <= 7)
              .toList();
    return JadwalBel(
      id: map['id'] as String,
      nama: (map['nama'] as String?) ?? '',
      jam: (map['jam'] as int?) ?? 0,
      menit: (map['menit'] as int?) ?? 0,
      daftarHari: hari,
      jumlahPengulangan: (map['pengulangan'] as int?) ?? 3,
      jedaDetik: (map['jedaDetik'] as int?) ?? 5,
      pathSuara: (map['pathSuara'] as String?) ?? '',
      volume: ((map['volume'] as num?) ?? 1.0).toDouble(),
      aktif: ((map['aktif'] as int?) ?? 1) == 1,
    );
  }
}
