import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Pengaturan global. Disimpan di SharedPreferences (lihat
// PengaturanProvider Tahap 4), bukan di SQLite.
class Pengaturan {
  final bool modeSenyap;
  final List<String> tanggalLibur;
  final String manualSuara;
  final double manualVolume;

  const Pengaturan({
    this.modeSenyap = false,
    this.tanggalLibur = const [],
    this.manualSuara = 'assets:bel_klasik.wav',
    this.manualVolume = 1.0,
  });

  Pengaturan copyWith({
    bool? modeSenyap,
    List<String>? tanggalLibur,
    String? manualSuara,
    double? manualVolume,
  }) {
    return Pengaturan(
      modeSenyap: modeSenyap ?? this.modeSenyap,
      tanggalLibur: tanggalLibur ?? List.of(this.tanggalLibur),
      manualSuara: manualSuara ?? this.manualSuara,
      manualVolume: manualVolume ?? this.manualVolume,
    );
  }

  bool isLibur(DateTime tanggal) {
    final y = tanggal.year.toString().padLeft(4, '0');
    final m = tanggal.month.toString().padLeft(2, '0');
    final d = tanggal.day.toString().padLeft(2, '0');
    return tanggalLibur.contains('$y-$m-$d');
  }

  /// Validasi tanggal "YYYY-MM-DD".
  static bool tanggalValid(String s) {
    final reg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!reg.hasMatch(s)) return false;
    try {
      final p = s.split('-');
      final dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      final ulang =
          '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
      return ulang == s;
    } catch (_) {
      return false;
    }
  }

  static String suaraDefault() => AppKonstanta.suaraBawaan.first.id;
}
