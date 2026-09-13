import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';
import 'package:bel_sekolah_otomatis/services/file_sound_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/widgets/hari_picker.dart';

// Form tambah / edit jadwal + preview suara.
class JadwalFormScreen extends ConsumerStatefulWidget {
  const JadwalFormScreen({super.key, this.existing});

  final JadwalBel? existing;

  @override
  ConsumerState<JadwalFormScreen> createState() => _JadwalFormScreenState();
}

class _JadwalFormScreenState extends ConsumerState<JadwalFormScreen> {
  late final TextEditingController _nama;
  late final TextEditingController _pengulangan;
  late final TextEditingController _jeda;
  late int _jam;
  late int _menit;
  late List<int> _hari;
  late String _suara;
  late double _volume;
  late bool _aktif;
  bool _previewBunyi = false;
  bool _simpanLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.nama ?? '');
    _pengulangan = TextEditingController(
      text: '${e?.jumlahPengulangan ?? 3}',
    );
    _jeda = TextEditingController(text: '${e?.jedaDetik ?? 5}');
    _jam = e?.jam ?? 7;
    _menit = e?.menit ?? 0;
    _hari = List.of(e?.daftarHari ?? [1, 2, 3, 4, 5]);
    _suara = e?.pathSuara ?? AppKonstanta.suaraBawaan.first.id;
    _volume = e?.volume ?? 1.0;
    _aktif = e?.aktif ?? true;
  }

  @override
  void dispose() {
    _nama.dispose();
    _pengulangan.dispose();
    _jeda.dispose();
    AudioService.instance.stop();
    super.dispose();
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _jam, minute: _menit),
    );
    if (hasil != null) {
      setState(() {
        _jam = hasil.hour;
        _menit = hasil.minute;
      });
    }
  }

  Future<void> _pilihFile() async {
    final path = await FileSoundService.pilihDanSimpan();
    if (path != null && mounted) {
      setState(() => _suara = path);
    }
  }

  Future<void> _togglePreview() async {
    if (_previewBunyi) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _previewBunyi = false);
      return;
    }
    final pengulangan = int.tryParse(_pengulangan.text) ?? 0;
    final jeda = int.tryParse(_jeda.text) ?? 0;
    setState(() => _previewBunyi = true);
    try {
      final error = await AudioService.instance.preview(
        pathSuara: _suara,
        volume: _volume,
        pengulangan: pengulangan < 1 ? 1 : pengulangan,
        jedaDetik: jeda < 0 ? 0 : jeda,
      );
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } finally {
      if (mounted) setState(() => _previewBunyi = false);
    }
  }

  Future<void> _simpan() async {
    final pengulangan = int.tryParse(_pengulangan.text.trim()) ?? -1;
    final jeda = int.tryParse(_jeda.text.trim()) ?? -1;

    final draft = _isEdit
        ? widget.existing!.copyWith(
            nama: _nama.text.trim(),
            jam: _jam,
            menit: _menit,
            daftarHari: _hari,
            jumlahPengulangan: pengulangan,
            jedaDetik: jeda,
            pathSuara: _suara,
            volume: _volume,
            aktif: _aktif,
          )
        : JadwalBel.baru(
            nama: _nama.text.trim(),
            jam: _jam,
            menit: _menit,
            daftarHari: _hari,
            jumlahPengulangan: pengulangan,
            jedaDetik: jeda,
            pathSuara: _suara,
            volume: _volume,
          );

    final err = draft.validasi();
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    setState(() => _simpanLoading = true);
    try {
      final gagal = _isEdit
          ? await ref.read(jadwalProvider.notifier).ubah(
              _isEdit && widget.existing!.aktif != _aktif
                  ? draft
                  : draft.copyWith(aktif: _aktif),
            )
          : await ref.read(jadwalProvider.notifier).tambah(draft);
      if (!mounted) return;
      if (gagal != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(gagal)));
      } else {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _simpanLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jamLabel =
        '${_jam.toString().padLeft(2, '0')}:${_menit.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nama', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: _nama,
            decoration: const InputDecoration(
              hintText: 'Contoh: Bel Masuk',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          const Text('Jam', style: _label),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pilihJam,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 12),
                  Text(
                    jamLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  const Text('Ubah'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Hari berlaku', style: _label),
          const SizedBox(height: 6),
          HariPicker(
            terpilih: _hari,
            onChanged: (v) => setState(() => _hari = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengulangan', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pengulangan,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        suffixText: 'x',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jeda (detik)', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _jeda,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        suffixText: 'dtk',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Suara', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _suaraBawaanValue(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final s in AppKonstanta.suaraBawaan)
                DropdownMenuItem(value: s.id, child: Text(s.label)),
              if (_isCustom())
                DropdownMenuItem(
                  value: _suara,
                  child: Text(FileSoundService.label(_suara)),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _suara = v);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pilihFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Pilih file mp3/wav sendiri'),
          ),
          if (_isCustom())
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'File: ${FileSoundService.label(_suara)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Volume ${(_volume * 100).round()}%',
            style: _label,
          ),
          Slider(
            value: _volume,
            onChanged: (v) => setState(() => _volume = v),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _togglePreview,
            icon: Icon(_previewBunyi ? Icons.stop : Icons.play_arrow),
            label: Text(_previewBunyi ? 'Stop preview' : 'Preview suara'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aktif'),
            value: _aktif,
            onChanged: (v) => setState(() => _aktif = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _simpanLoading ? null : _simpan,
              child: _simpanLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isEdit ? 'Simpan' : 'Tambah'),
            ),
          ),
        ],
      ),
    );
  }

  String? _suaraBawaanValue() {
    for (final s in AppKonstanta.suaraBawaan) {
      if (s.id == _suara) return _suara;
    }
    return _isCustom() ? _suara : AppKonstanta.suaraBawaan.first.id;
  }

  bool _isCustom() {
    for (final s in AppKonstanta.suaraBawaan) {
      if (s.id == _suara) return false;
    }
    return true;
  }
}

const TextStyle _label = TextStyle(fontWeight: FontWeight.w600);
