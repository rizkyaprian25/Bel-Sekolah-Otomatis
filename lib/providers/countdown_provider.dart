import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';

// Data hitung mundur untuk dashboard. Diupdate tiap detik.
class Countdown {
  final BelBerikutnya? berikutnya;
  final Duration sisa;

  const Countdown({this.berikutnya, this.sisa = Duration.zero});

  bool get ada => berikutnya != null;
}

final countdownProvider = StreamProvider.autoDispose<Countdown>((ref) async* {
  // Watch agar stream dibuat ulang saat data berubah.
  final semua = ref.watch(jadwalProvider).semua;
  final atur = ref.watch(pengaturanProvider);

  while (true) {
    final now = DateTime.now();
    final next = SchedulerService.cariBerikutnya(semua, atur, now);
    if (next == null) {
      yield const Countdown();
    } else {
      yield Countdown(
        berikutnya: next,
        sisa: next.waktu.difference(now),
      );
    }
    await Future.delayed(const Duration(seconds: 1));
  }
});
