import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/screens/jadwal_form_screen.dart';
import 'package:bel_sekolah_otomatis/widgets/jadwal_tile.dart';

// Daftar semua jadwal + tambah, edit, duplikat, hapus, toggle.
class JadwalListScreen extends ConsumerWidget {
  const JadwalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jadwalProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Jadwal (${state.semua.length})')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(jadwalProvider.notifier).muat(),
        child: _body(context, ref, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JadwalFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, JadwalState state) {
    if (state.loading && state.semua.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.semua.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(jadwalProvider.notifier).muat(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (state.semua.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.alarm_off, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('Belum ada jadwal. Tekan Tambah.')),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: state.semua.length,
      itemBuilder: (c, i) {
        final j = state.semua[i];
        return JadwalTile(
          jadwal: j,
          onToggle: (v) =>
              ref.read(jadwalProvider.notifier).toggle(j.id, v),
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JadwalFormScreen(existing: j),
            ),
          ),
          onDuplikat: () async {
            final err = await ref
                .read(jadwalProvider.notifier)
                .duplikat(j.id);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(err)));
            }
          },
          onHapus: () => _konfirmasiHapus(context, ref, j.id, j.nama),
        );
      },
    );
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
        content: Text('Hapus "$nama"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(c).pop();
              final err = await ref
                  .read(jadwalProvider.notifier)
                  .hapus(id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
