import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Validasi jadwal menolak nama kosong dan hari kosong', () {
    final j = JadwalBel.baru(
      nama: '  ',
      jam: 7,
      menit: 0,
      daftarHari: const [],
      pathSuara: 'assets:bel_klasik.wav',
    );
    expect(j.validasi(), isNotNull);
  });

  test('Hari label Senin-Jumat dan setiap hari', () {
    final seninJumat = JadwalBel.baru(
      nama: 'Masuk',
      jam: 7,
      menit: 0,
      daftarHari: const [1, 2, 3, 4, 5],
      pathSuara: 'assets:bel_klasik.wav',
    );
    expect(seninJumat.hariLabel, 'Senin-Jumat');
    expect(seninJumat.jamLabel, '07:00');
  });

  test('cariBerikutnya lewati mode senyap dan tanggal libur', () {
    final jadwal = JadwalBel.baru(
      nama: 'Masuk',
      jam: 7,
      menit: 0,
      daftarHari: const [1, 2, 3, 4, 5, 6, 7],
      pathSuara: 'assets:bel_klasik.wav',
    );
    final now = DateTime(2026, 9, 7, 6, 0); // Senin 06:00
    final normal = SchedulerService.cariBerikutnya(
      [jadwal],
      const Pengaturan(),
      now,
    );
    expect(normal, isNotNull);
    expect(normal!.waktu, DateTime(2026, 9, 7, 7, 0));

    final senyap = SchedulerService.cariBerikutnya(
      [jadwal],
      const Pengaturan(modeSenyap: true),
      now,
    );
    expect(senyap, isNull);

    final libur = SchedulerService.cariBerikutnya(
      [jadwal],
      const Pengaturan(tanggalLibur: ['2026-09-07']),
      now,
    );
    expect(libur, isNotNull);
    expect(libur!.waktu, DateTime(2026, 9, 8, 7, 0));
  });

  test('Format jam dan durasi', () {
    expect(formatJamMenit(7, 5), '07:05');
    expect(formatDurasi(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03');
    expect(tanggalKey(DateTime(2026, 9, 7)), '2026-09-07');
  });
}
