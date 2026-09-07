import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/countdown_provider.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/screens/jadwal_form_screen.dart';
import 'package:bel_sekolah_otomatis/widgets/bel_manual_button.dart';
import 'package:bel_sekolah_otomatis/widgets/countdown_card.dart';
import 'package:bel_sekolah_otomatis/widgets/jadwal_tile.dart';

// Beranda: countdown, banner status, jadwal hari ini, bel manual.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwalState = ref.watch(jadwalProvider);
    final hariIni = ref.watch(jadwalHariIniProvider);
    final atur = ref.watch(pengaturanProvider);
    final cd = ref.watch(countdownProvider).valueOrNull;
    final nextId = cd?.berikutnya?.jadwal.id;

    return RefreshIndicator(
      onRefresh: () => ref.read(jadwalProvider.notifier).muat(),
      child: ListView(
        children: [
          const CountdownCard(),
          if (atur.modeSenyap)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Text(
                'Mode senyap aktif. Semua bel tidak akan berbunyi. '
                'Matikan di menu Pengaturan.',
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Jadwal hari ini (${hariIni.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (jadwalState.loading && hariIni.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hariIni.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Tidak ada jadwal untuk hari ini.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JadwalFormScreen(),
                      ),
                    ),
                    child: const Text('Tambah jadwal'),
                  ),
                ],
              ),
            )
          else
            for (final j in hariIni)
              JadwalTile(
                jadwal: j,
                isBerikutnya: j.id == nextId,
                sudahLewat: _sudahLewat(j),
                onToggle: (v) =>
                    ref.read(jadwalProvider.notifier).toggle(j.id, v),
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JadwalFormScreen(existing: j),
                  ),
                ),
                onDuplikat: () =>
                    ref.read(jadwalProvider.notifier).duplikat(j.id),
                onHapus: () => _konfirmasiHapus(context, ref, j.id, j.nama),
              ),
          const SizedBox(height: 8),
          const BelManualButton(),
        ],
      ),
    );
  }

  bool _sudahLewat(dynamic j) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, j.jam, j.menit);
    return target.isBefore(now);
  }

  void _konfirmasiHapus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String nama,
  ) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus jadwal'),
        content: Text('Hapus "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(c).pop();
              ref.read(jadwalProvider.notifier).hapus(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
