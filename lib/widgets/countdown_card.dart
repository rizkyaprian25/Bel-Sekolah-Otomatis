import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/countdown_provider.dart';
import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

// Kartu bel berikutnya + hitung mundur besar. Update tiap detik.
class CountdownCard extends ConsumerWidget {
  const CountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(countdownProvider);
    final atur = ref.watch(pengaturanProvider);

    return Card(
      margin: const EdgeInsets.all(12),
      color: const Color(AppKonstanta.navy),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const SizedBox(
            height: 90,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (e, _) => _isi('Bel berikutnya', 'Tidak tersedia', '-'),
          data: (cd) {
            if (atur.modeSenyap) {
              return _isi(
                'Mode senyap aktif',
                'Semua bel dinonaktifkan sementara',
                '--:--:--',
              );
            }
            if (!cd.ada) {
              return _isi(
                'Tidak ada bel berikutnya',
                'Belum ada jadwal aktif 7 hari ke depan',
                '--:--:--',
              );
            }
            final j = cd.berikutnya!.jadwal;
            final w = cd.berikutnya!.waktu;
            final now = DateTime.now();
            final hariIni = DateTime(now.year, now.month, now.day);
            final tglBel = DateTime(w.year, w.month, w.day);
            final beda = tglBel.difference(hariIni).inDays;
            final kapan = beda == 0
                ? 'Hari ini'
                : beda == 1
                ? 'Besok'
                : AppKonstanta.namaHari[w.weekday];
            return _isi(
              'Berikutnya: ${j.nama}',
              '$kapan pukul ${j.jamLabel}',
              formatDurasi(cd.sisa),
            );
          },
        ),
      ),
    );
  }

  Widget _isi(String atas, String tengah, String countdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(atas, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          tengah,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          countdown,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
