import 'package:bel_sekolah_otomatis/models/jp_generator_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JpGeneratorConfig Senin-Kamis 9 JP 35 menit dengan istirahat 30 menit', () {
    final config = JpGeneratorConfig(
      daftarHari: const [1, 2, 3, 4],
      jamMulai: 7,
      menitMulai: 0,
      adaKegiatanAwal: false,
      jumlahJp: 9,
      durasiJpMenit: 35,
      istirahat1Aktif: true,
      setelahJpKe1: 4,
      durasiIstirahat1Menit: 30,
      istirahat2Aktif: false,
    );

    final pratinjau = config.buatPratinjau();

    // 1 Masuk, 8 Pergantian, 1 Istirahat, 1 Pulang = 11 bel
    expect(pratinjau.length, 11);

    // Bel Masuk Sekolah (JP 1) @ 07:00
    expect(pratinjau[0].nama, 'Bel Masuk Sekolah (JP 1)');
    expect(pratinjau[0].jamLabel, '07:00');

    // Bel Pergantian Jam (Masuk JP 2) @ 07:35
    expect(pratinjau[1].nama, 'Bel Pergantian Jam (Masuk JP 2)');
    expect(pratinjau[1].jamLabel, '07:35');

    // JP 3 @ 08:10
    expect(pratinjau[2].jamLabel, '08:10');

    // JP 4 @ 08:45
    expect(pratinjau[3].jamLabel, '08:45');

    // Istirahat 1 @ 09:20 (08:45 + 35)
    expect(pratinjau[4].nama, 'Bel Istirahat 1');
    expect(pratinjau[4].jamLabel, '09:20');

    // Bel Masuk Selesai Istirahat (JP 5) @ 09:50 (09:20 + 30)
    expect(pratinjau[5].nama, 'Bel Masuk Selesai Istirahat (JP 5)');
    expect(pratinjau[5].jamLabel, '09:50');

    // JP 6 @ 10:25
    expect(pratinjau[6].jamLabel, '10:25');

    // JP 7 @ 11:00
    expect(pratinjau[7].jamLabel, '11:00');

    // JP 8 @ 11:35
    expect(pratinjau[8].jamLabel, '11:35');

    // JP 9 @ 12:10
    expect(pratinjau[9].jamLabel, '12:10');

    // Pulang @ 12:45 (12:10 + 35)
    expect(pratinjau[10].nama, 'Bel Pulang Sekolah');
    expect(pratinjau[10].jamLabel, '12:45');

    // Generate JadwalBel
    final jadwals = config.generateJadwal();
    expect(jadwals.length, 11);
    expect(jadwals.first.daftarHari, [1, 2, 3, 4]);
  });

  test('JpGeneratorConfig dengan Upacara hari Senin', () {
    final config = JpGeneratorConfig(
      daftarHari: const [1],
      jamMulai: 7,
      menitMulai: 0,
      adaKegiatanAwal: true,
      namaKegiatanAwal: 'Upacara Bendera',
      durasiKegiatanAwalMenit: 45,
      jumlahJp: 4,
      durasiJpMenit: 35,
      istirahat1Aktif: true,
      setelahJpKe1: 2,
      durasiIstirahat1Menit: 20,
      istirahat2Aktif: false,
    );

    final pratinjau = config.buatPratinjau();

    // 07:00 Upacara
    expect(pratinjau[0].nama, 'Bel Masuk - Upacara Bendera');
    expect(pratinjau[0].jamLabel, '07:00');

    // 07:45 Masuk JP 1
    expect(pratinjau[1].nama, 'Bel Masuk JP 1');
    expect(pratinjau[1].jamLabel, '07:45');

    // 08:20 Masuk JP 2
    expect(pratinjau[2].jamLabel, '08:20');

    // 08:55 Istirahat 1
    expect(pratinjau[3].nama, 'Bel Istirahat 1');
    expect(pratinjau[3].jamLabel, '08:55');

    // 09:15 Masuk Selesai Istirahat (JP 3)
    expect(pratinjau[4].nama, 'Bel Masuk Selesai Istirahat (JP 3)');
    expect(pratinjau[4].jamLabel, '09:15');

    // 09:50 Masuk JP 4
    expect(pratinjau[5].jamLabel, '09:50');

    // 10:25 Pulang
    expect(pratinjau[6].nama, 'Bel Pulang Sekolah');
    expect(pratinjau[6].jamLabel, '10:25');
  });

  test('JpGeneratorConfig Jumat 5 JP 30 menit', () {
    final config = JpGeneratorConfig.jumatDefault();
    final pratinjau = config.buatPratinjau();

    // 07:00 Masuk JP 1
    expect(pratinjau[0].jamLabel, '07:00');
    // 07:30 JP 2
    expect(pratinjau[1].jamLabel, '07:30');
    // 08:00 JP 3
    expect(pratinjau[2].jamLabel, '08:00');
    // 08:30 Istirahat 1 (25 menit)
    expect(pratinjau[3].nama, 'Bel Istirahat 1');
    expect(pratinjau[3].jamLabel, '08:30');
    // 08:55 JP 4
    expect(pratinjau[4].jamLabel, '08:55');
    // 09:25 JP 5
    expect(pratinjau[5].jamLabel, '09:25');
    // 09:55 Pulang
    expect(pratinjau[6].nama, 'Bel Pulang Sekolah');
    expect(pratinjau[6].jamLabel, '09:55');
  });
}
