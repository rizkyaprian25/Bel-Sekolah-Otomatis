// Helper waktu: format, countdown, dan pencocokan hari.

/// Format "07:05" dari jam dan menit.
String formatJamMenit(int jam, int menit) {
  final j = jam.toString().padLeft(2, '0');
  final m = menit.toString().padLeft(2, '0');
  return '$j:$m';
}

/// Format durasi countdown menjadi "HH:MM:SS".
String formatDurasi(Duration d) {
  if (d.isNegative) return '00:00:00';
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Key tanggal "YYYY-MM-DD" untuk daftar pengecualian.
String tanggalKey(DateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parse "YYYY-MM-DD" ke DateTime (jam 00:00). Return null jika invalid.
DateTime? parseTanggalKey(String s) {
  try {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}

/// Waktu bel berikutnya untuk jam:menit tertentu pada hari ini.
/// Jika jam sudah lewat, kembalikan jadwal besok di jam yang sama.
DateTime waktuBerikutnya(int jam, int menit, {DateTime? dari}) {
  final now = dari ?? DateTime.now();
  var target = DateTime(now.year, now.month, now.day, jam, menit);
  if (!target.isAfter(now)) {
    target = target.add(const Duration(days: 1));
  }
  return target;
}

/// Cek apakah jadwal dengan daftarHari berlaku pada tanggal [t].
/// daftarHari memakai 1-7 (Senin-Minggu, sama dengan DateTime.weekday).
bool berlakuPadaTanggal(List<int> daftarHari, DateTime t) {
  return daftarHari.contains(t.weekday);
}

/// Tambah atau kurangi menit pada (jam, menit), menghasilkan (jam, menit) baru (0-23, 0-59).
({int jam, int menit}) tambahMenit(int jam, int menit, int selisihMenit) {
  final total = (jam * 60 + menit + selisihMenit);
  final normalized = (total % 1440 + 1440) % 1440;
  return (jam: normalized ~/ 60, menit: normalized % 60);
}

