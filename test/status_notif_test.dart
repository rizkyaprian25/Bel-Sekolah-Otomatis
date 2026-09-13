import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MediaStyleInformation didukung pada AndroidNotificationDetails', () {
    const details = AndroidNotificationDetails(
      'bel_sekolah_status_channel',
      'Status Bel Sekolah',
      ongoing: true,
      autoCancel: false,
      styleInformation: MediaStyleInformation(
        htmlFormatContent: false,
        htmlFormatTitle: false,
      ),
      category: AndroidNotificationCategory.transport,
    );
    expect(details.ongoing, isTrue);
    expect(details.autoCancel, isFalse);
    expect(details.styleInformation, isA<MediaStyleInformation>());
  });

  test('SchedulerService.cariBerikutnya mendeteksi bel berikutnya dengan akurat', () {
    const jadwal1 = JadwalBel(
      id: '1',
      nama: 'Bel Masuk',
      jam: 7,
      menit: 0,
      daftarHari: [1, 2, 3, 4, 5],
      pathSuara: 'assets:ai_masuk_jp1.mp3',
    );
    const jadwal2 = JadwalBel(
      id: '2',
      nama: 'Bel Istirahat',
      jam: 9,
      menit: 30,
      daftarHari: [1, 2, 3, 4, 5],
      pathSuara: 'assets:ai_istirahat.mp3',
    );

    // Waktu simulasi: Senin pukul 08:00 (setelah JP1, sebelum Istirahat)
    // 2026-09-14 adalah hari Senin (weekday 1)
    final now = DateTime(2026, 9, 14, 8, 0);
    const atur = Pengaturan(modeSenyap: false);

    final berikutnya = SchedulerService.cariBerikutnya([jadwal1, jadwal2], atur, now);
    expect(berikutnya, isNotNull);
    expect(berikutnya!.jadwal.nama, 'Bel Istirahat');
    expect(berikutnya.waktu.hour, 9);
    expect(berikutnya.waktu.minute, 30);
  });
}
