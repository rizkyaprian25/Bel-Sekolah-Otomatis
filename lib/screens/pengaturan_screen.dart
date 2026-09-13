import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';
import 'package:bel_sekolah_otomatis/services/file_sound_service.dart';
import 'package:bel_sekolah_otomatis/services/permission_service.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Pengaturan umum: mode senyap, izin, bel manual, tanggal libur.
class PengaturanScreen extends ConsumerStatefulWidget {
  const PengaturanScreen({super.key});

  @override
  ConsumerState<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends ConsumerState<PengaturanScreen> {
  StatusIzin? _izin;
  bool _testBunyi = false;

  @override
  void initState() {
    super.initState();
    _muatIzin();
  }

  Future<void> _muatIzin() async {
    final s = await PermissionService.cekStatus();
    if (mounted) setState(() => _izin = s);
  }

  Future<void> _mintaIzin() async {
    await PermissionService.mintaIzinAwal();
    await _muatIzin();
  }

  Future<void> _tambahLibur() async {
    final now = DateTime.now();
    final pilih = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (pilih == null || !mounted) return;
    final key =
        '${pilih.year.toString().padLeft(4, '0')}-'
        '${pilih.month.toString().padLeft(2, '0')}-'
        '${pilih.day.toString().padLeft(2, '0')}';
    final err = await ref
        .read(pengaturanProvider.notifier)
        .tambahLibur(key);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _testManual() async {
    if (_testBunyi) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _testBunyi = false);
      return;
    }
    final atur = ref.read(pengaturanProvider);
    setState(() => _testBunyi = true);
    try {
      final err = await AudioService.instance.belManual(
        pathSuara: atur.manualSuara,
        volume: atur.manualVolume,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _testBunyi = false);
    }
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atur = ref.watch(pengaturanProvider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _kartu(
          title: 'Mode senyap',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nonaktifkan semua bel sementara'),
            subtitle: const Text('Untuk libur atau ujian. Jadwal tetap tersimpan.'),
            value: atur.modeSenyap,
            onChanged: (v) =>
                ref.read(pengaturanProvider.notifier).setModeSenyap(v),
          ),
        ),
        _kartu(
          title: 'Izin sistem',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_izin?.ringkasan ?? 'Memeriksa izin...'),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _mintaIzin,
                    child: const Text('Minta izin'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: PermissionService.bukaPengaturan,
                    child: const Text('Buka pengaturan'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Agar bel akurat, aktifkan Alarm Tepat Waktu dan '
                'nonaktifkan optimasi baterai untuk aplikasi ini.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        _kartu(
          title: 'Bel manual default',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _manualValue(atur),
                decoration: const InputDecoration(
                  labelText: 'Suara',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in AppKonstanta.suaraBawaan)
                    DropdownMenuItem(value: s.id, child: Text(s.label)),
                  if (_manualIsCustom(atur))
                    DropdownMenuItem(
                      value: atur.manualSuara,
                      child: Text(FileSoundService.label(atur.manualSuara)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(pengaturanProvider.notifier).setManualSuara(v);
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await FileSoundService.pilihDanSimpan();
                  if (p != null) {
                    ref.read(pengaturanProvider.notifier).setManualSuara(p);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Pilih file sendiri'),
              ),
              const SizedBox(height: 8),
              Text('Volume ${((atur.manualVolume) * 100).round()}%'),
              Slider(
                value: atur.manualVolume,
                onChanged: (v) => ref
                    .read(pengaturanProvider.notifier)
                    .setManualVolume(v),
              ),
              OutlinedButton.icon(
                onPressed: _testManual,
                icon: Icon(_testBunyi ? Icons.stop : Icons.play_arrow),
                label: Text(_testBunyi ? 'Stop' : 'Test suara'),
              ),
            ],
          ),
        ),
        _kartu(
          title: 'Tanggal libur (${atur.tanggalLibur.length})',
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pada tanggal ini bel tidak berbunyi.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              if (atur.tanggalLibur.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Belum ada tanggal libur.'),
                )
              else
                for (final t in atur.tanggalLibur)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.event_busy, size: 20),
                    title: Text(_formatTanggal(t)),
                    subtitle: Text(t),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(pengaturanProvider.notifier)
                          .hapusLibur(t),
                    ),
                  ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _tambahLibur,
                icon: const Icon(Icons.add),
                label: const Text('Tambah tanggal libur'),
              ),
            ],
          ),
        ),
        _kartu(
          title: 'Pemeliharaan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await SchedulerService.rescheduleAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua alarm dijadwalkan ulang')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Jadwalkan ulang semua alarm'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kartu({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  String _manualValue(Pengaturan atur) {
    for (final s in AppKonstanta.suaraBawaan) {
      if (s.id == atur.manualSuara) return atur.manualSuara;
    }
    return _manualIsCustom(atur)
        ? atur.manualSuara
        : AppKonstanta.suaraBawaan.first.id;
  }

  bool _manualIsCustom(Pengaturan atur) {
    for (final s in AppKonstanta.suaraBawaan) {
      if (s.id == atur.manualSuara) return false;
    }
    return true;
  }

  String _formatTanggal(String key) {
    try {
      final p = key.split('-');
      final dt = DateTime(
        int.parse(p[0]),
        int.parse(p[1]),
        int.parse(p[2]),
      );
      return DateFormat('EEEE, d MMM yyyy', 'id').format(dt);
    } catch (_) {
      return key;
    }
  }
}
