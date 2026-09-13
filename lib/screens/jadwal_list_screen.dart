import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/jp_generator_config.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/screens/jadwal_form_screen.dart';
import 'package:bel_sekolah_otomatis/screens/jp_generator_screen.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/widgets/dialog_geser_jadwal.dart';
import 'package:bel_sekolah_otomatis/widgets/jadwal_tile.dart';

class JadwalListScreen extends ConsumerStatefulWidget {
  const JadwalListScreen({super.key});

  @override
  ConsumerState<JadwalListScreen> createState() => _JadwalListScreenState();
}

class _JadwalListScreenState extends ConsumerState<JadwalListScreen> {
  // Mode tampilan: default adalah Paket Per Hari (1 kesatuan), bukan pecah-pecah bel.
  bool _tampilanPerHari = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jadwalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tampilanPerHari
              ? 'Jadwal Pelajaran Sekolah'
              : 'Semua Bel (${state.semua.length})',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JpGeneratorScreen()),
            ),
            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.amberAccent,
              size: 18,
            ),
            label: const Text(
              'Atur JP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(jadwalProvider.notifier).muat(),
        child: _body(context, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _tampilanPerHari
                ? const JpGeneratorScreen()
                : const JadwalFormScreen(),
          ),
        ),
        icon: Icon(_tampilanPerHari ? Icons.auto_awesome : Icons.add),
        label: Text(_tampilanPerHari ? 'Atur JP Baru' : 'Tambah Bel'),
      ),
    );
  }

  Widget _body(BuildContext context, JadwalState state) {
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

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        // Pilihan Mode Tampilan: Paket 1 Kesatuan vs Semua Bel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.calendar_month, size: 18),
                label: Text(
                  'Paket Per Hari (1 Kesatuan)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.format_list_bulleted, size: 18),
                label: Text(
                  'Semua Bel Rinci',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            selected: {_tampilanPerHari},
            onSelectionChanged: (set) {
              setState(() => _tampilanPerHari = set.first);
            },
          ),
        ),
        const SizedBox(height: 6),

        if (_tampilanPerHari) ...[
          // Menampilkan 1 kesatuan per hari (Senin s/d Minggu)
          for (var hari = 1; hari <= 7; hari++)
            _buildKartuHari(
              context,
              hari: hari,
              semuaJadwal: state.semua,
            ),
        ] else ...[
          // Tampilan flat lama jika ingin melihat semua bel individu
          for (final j in state.semua)
            JadwalTile(
              jadwal: j,
              onToggle: (v) =>
                  ref.read(jadwalProvider.notifier).toggle(j.id, v),
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JadwalFormScreen(existing: j),
                ),
              ),
              onDuplikat: () async {
                final err =
                    await ref.read(jadwalProvider.notifier).duplikat(j.id);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              },
              onHapus: () => _konfirmasiHapusSatuBel(context, j.id, j.nama),
            ),
        ],
      ],
    );
  }

  Widget _buildKartuHari(
    BuildContext context, {
    required int hari,
    required List<JadwalBel> semuaJadwal,
  }) {
    final namaHari = AppKonstanta.namaHari[hari];
    final jadwalHari = semuaJadwal.where((j) => j.daftarHari.contains(hari)).toList()
      ..sort((a, b) => (a.jam * 60 + a.menit).compareTo(b.jam * 60 + b.menit));

    final adaJadwal = jadwalHari.isNotEmpty;

    if (!adaJadwal) {
      // Hari libur / belum disetting
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Text(
                    namaHari,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• Libur / Belum ada bel',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JpGeneratorScreen(initialHari: [hari]),
                  ),
                ),
                child: const Text('+ Atur Jadwal'),
              ),
            ],
          ),
        ),
      );
    }

    final bool semuaAktif = jadwalHari.every((j) => j.aktif);
    final jamAwal = jadwalHari.first.jamLabel;
    final jamAkhir = jadwalHari.last.jamLabel;
    final jumlahJp = jadwalHari
        .where((j) => j.nama.contains('Jam Ke') || j.nama.contains('JP'))
        .length;
    final adaIstirahat =
        jadwalHari.any((j) => j.nama.toLowerCase().contains('istirahat'));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: semuaAktif
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hari & Sakelar Aktif/Nonaktif 1 Hari
          ListTile(
            leading: CircleAvatar(
              backgroundColor: semuaAktif
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              child: Text(
                AppKonstanta.namaHariSingkat[hari],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(
                  namaHari,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: semuaAktif
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: semuaAktif
                          ? Colors.green.shade300
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: Text(
                    semuaAktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: semuaAktif
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '$jamAwal s/d $jamAkhir • $jumlahJp JP${adaIstirahat ? " + Istirahat" : ""}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: Switch(
              value: semuaAktif,
              onChanged: (v) =>
                  ref.read(jadwalProvider.notifier).toggleHari(hari, v),
            ),
          ),

          const Divider(height: 1),

          // Tombol Aksi 1 Kesatuan Hari
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Atur / Edit Jadwal Hari Ini'),
                  onPressed: () async {
                    final saved =
                        await JpGeneratorConfig.bacaConfigHari(hari);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JpGeneratorScreen(
                          initialConfig: saved,
                          initialHari: [hari],
                        ),
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.update, size: 16),
                  label: const Text('Geser Jam'),
                  onPressed: () {
                    DialogGeserJadwal.tampilkan(
                      context,
                      hari: hari,
                      jadwalHariIni: jadwalHari,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Hapus jadwal hari ini',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _konfirmasiHapusHari(context, hari, namaHari),
                ),
              ],
            ),
          ),

          // Dropdown Accordion untuk melihat rincian bel jika diperlukan
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              dense: true,
              title: Text(
                'Lihat rincian ${jadwalHari.length} bel otomatis',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              children: [
                Container(
                  color: Colors.grey.shade50,
                  child: Column(
                    children: [
                      for (final j in jadwalHari)
                        JadwalTile(
                          jadwal: j,
                          onToggle: (v) => ref
                              .read(jadwalProvider.notifier)
                              .toggle(j.id, v),
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                          onHapus: () =>
                              _konfirmasiHapusSatuBel(context, j.id, j.nama),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapusHari(BuildContext context, int hari, String namaHari) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Hapus Semua Bel Hari $namaHari?'),
        content: Text(
          'Seluruh jadwal bel pelajaran pada hari $namaHari akan dihapus sekaligus sebagai satu kesatuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(c).pop();
              final err =
                  await ref.read(jadwalProvider.notifier).hapusHari(hari);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text('Hapus Hari Ini'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapusSatuBel(
    BuildContext context,
    String id,
    String nama,
  ) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus bel'),
        content: Text('Hapus "$nama"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(c).pop();
              final err =
                  await ref.read(jadwalProvider.notifier).hapus(id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
