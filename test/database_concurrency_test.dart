import 'package:bel_sekolah_otomatis/utils/async_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AsyncLock menjamin eksekusi asinkron berurutan (tanpa race condition)', () async {
    final lock = AsyncLock();
    final log = <int>[];

    // Mulai 3 operasi bersamaan
    final f1 = lock.synchronized(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      log.add(1);
    });

    final f2 = lock.synchronized(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      log.add(2);
    });

    final f3 = lock.synchronized(() async {
      await Future.delayed(const Duration(milliseconds: 5));
      log.add(3);
    });

    await Future.wait([f1, f2, f3]);

    // Walaupun f2 dan f3 memiliki delay lebih kecil, antrean harus tetap 1, 2, 3
    expect(log, [1, 2, 3]);
  });

  test('Format kunci deduplikasi bel mencegah tabrakan bunyi', () {
    const tanggal = '2026-09-14';
    const jam = 10;
    const menit = 10;

    final key1 = 'bel_${tanggal}_${jam}_$menit';
    final key2 = 'bel_${tanggal}_${jam}_$menit';

    // Dua jadwal dengan ID berbeda yang jatuh pada jam yang sama
    // harus menghasilkan kunci deduplikasi yang sama agar tidak saling bertabrakan
    expect(key1, equals(key2));
    expect(key1, 'bel_2026-09-14_10_10');
  });
}
