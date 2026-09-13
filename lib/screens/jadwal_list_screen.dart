import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/screens/jadwal_form_screen.dart';
import 'package:bel_sekolah_otomatis/screens/jp_generator_screen.dart';
import 'package:bel_sekolah_otomatis/widgets/jadwal_tile.dart';

// Daftar semua jadwal + tambah, edit, duplikat, hapus, toggle.
class JadwalListScreen extends ConsumerWidget {
  const JadwalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jadwalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal (${state.semua.length})'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JpGeneratorScreen()),
            ),
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
            label: const Text(
              'Atur JP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.alarm_off, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Belum ada jadwal bel sekolah.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Susun jadwal pelajaran sekolah secara otomatis atau tambah jadwal satu per satu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JpGeneratorScreen()),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Atur Jam Pelajaran (JP) Sekolah'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JadwalFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bel Manual Satu Per Satu'),
          ),
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
