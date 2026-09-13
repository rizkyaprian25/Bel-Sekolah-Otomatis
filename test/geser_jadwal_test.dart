import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tambahMenit kalkulasi pergeseran waktu dengan benar', () {
    // 07:00 + 15 menit -> 07:15
    final r1 = tambahMenit(7, 0, 15);
    expect(r1.jam, 7);
    expect(r1.menit, 15);

    // 07:45 + 20 menit -> 08:05
    final r2 = tambahMenit(7, 45, 20);
    expect(r2.jam, 8);
    expect(r2.menit, 5);

    // 08:10 - 15 menit -> 07:55
    final r3 = tambahMenit(8, 10, -15);
    expect(r3.jam, 7);
    expect(r3.menit, 55);

    // 23:50 + 15 menit -> 00:05 (melewati tengah malam)
    final r4 = tambahMenit(23, 50, 15);
    expect(r4.jam, 0);
    expect(r4.menit, 5);
  });

  test('Simulasi pergeseran jadwal keterlambatan sekolah', () {
    final jadwalSemula = [
      JadwalBel.baru(
        nama: 'Bel Masuk (JP 1)',
        jam: 7,
        menit: 0,
        daftarHari: const [1],
        pathSuara: 'assets:ai_masuk_jp1.mp3',
      ),
      JadwalBel.baru(
        nama: 'Bel Pergantian Jam (Masuk JP 2)',
        jam: 7,
        menit: 35,
        daftarHari: const [1],
        pathSuara: 'assets:ai_jam_ke_2.mp3',
      ),
      JadwalBel.baru(
        nama: 'Bel Istirahat 1',
        jam: 9,
        menit: 20,
        daftarHari: const [1],
        pathSuara: 'assets:ai_istirahat.mp3',
      ),
      JadwalBel.baru(
        nama: 'Bel Pulang Sekolah',
        jam: 12,
        menit: 45,
        daftarHari: const [1],
        pathSuara: 'assets:ai_pulang.mp3',
      ),
    ];

    // Sekolah terlambat 20 menit: geser +20 menit
    const selisih = 20;
    final jadwalDigeser = jadwalSemula.map((j) {
      final baru = tambahMenit(j.jam, j.menit, selisih);
      return j.copyWith(jam: baru.jam, menit: baru.menit);
    }).toList();

    expect(jadwalDigeser[0].jamLabel, '07:20');
    expect(jadwalDigeser[1].jamLabel, '07:55');
    expect(jadwalDigeser[2].jamLabel, '09:40');
    expect(jadwalDigeser[3].jamLabel, '13:05');

    // Reset kembali ke jam normal: geser -20 menit
    final jadwalDireset = jadwalDigeser.map((j) {
      final baru = tambahMenit(j.jam, j.menit, -selisih);
      return j.copyWith(jam: baru.jam, menit: baru.menit);
    }).toList();

    expect(jadwalDireset[0].jamLabel, '07:00');
    expect(jadwalDireset[1].jamLabel, '07:35');
    expect(jadwalDireset[2].jamLabel, '09:20');
    expect(jadwalDireset[3].jamLabel, '12:45');
  });
}
