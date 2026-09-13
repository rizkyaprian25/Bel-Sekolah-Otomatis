import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

class DialogGeserJadwal extends ConsumerStatefulWidget {
  const DialogGeserJadwal({
    super.key,
    required this.hari,
    required this.jadwalHariIni,
  });

  final int hari;
  final List<JadwalBel> jadwalHariIni;

  static Future<void> tampilkan(
    BuildContext context, {
    required int hari,
    required List<JadwalBel> jadwalHariIni,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialogGeserJadwal(
        hari: hari,
        jadwalHariIni: jadwalHariIni,
      ),
    );
  }

  @override
  ConsumerState<DialogGeserJadwal> createState() => _DialogGeserJadwalState();
}

class _DialogGeserJadwalState extends ConsumerState<DialogGeserJadwal> {
  int _selisihPilihan = 15; // default +15 menit
  int _akumulasiSaatIni = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatAkumulasi();
  }

  Future<void> _muatAkumulasi() async {
    final akumulasi =
        await ref.read(jadwalProvider.notifier).getPergeseranHari(widget.hari);
    if (mounted) {
      setState(() {
        _akumulasiSaatIni = akumulasi;
        _loading = false;
      });
    }
  }

  Future<void> _pilihJamMulaiBaru() async {
    if (widget.jadwalHariIni.isEmpty) return;
    final belPertama = widget.jadwalHariIni.first;
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: belPertama.jam, minute: belPertama.menit),
    );
    if (hasil != null && mounted) {
      final menitLama = belPertama.jam * 60 + belPertama.menit;
      final menitBaru = hasil.hour * 60 + hasil.minute;
      final selisih = menitBaru - menitLama;
      if (selisih != 0) {
        setState(() => _selisihPilihan = selisih);
      }
    }
  }

  Future<void> _terapkanPergeseran() async {
    if (_selisihPilihan == 0) return;
    Navigator.of(context).pop();

    final err = await ref.read(jadwalProvider.notifier).geserJadwalHari(
          hari: widget.hari,
          selisihMenit: _selisihPilihan,
        );

    if (mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal hari ${AppKonstanta.namaHari[widget.hari]} berhasil digeser '
              '${_selisihPilihan > 0 ? "+$_selisihPilihan" : "$_selisihPilihan"} menit.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  Future<void> _kembalikanNormal() async {
    Navigator.of(context).pop();
    final err = await ref
        .read(jadwalProvider.notifier)
        .resetPergeseranHari(widget.hari);

    if (mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal hari ${AppKonstanta.namaHari[widget.hari]} berhasil dikembalikan ke jam normal.',
            ),
            backgroundColor: Colors.blue.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final namaHari = AppKonstanta.namaHari[widget.hari];
    final list = widget.jadwalHariIni;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.update, color: Color(AppKonstanta.navy)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Penyesuaian Keterlambatan ($namaHari)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(AppKonstanta.navy),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Banner jika sedang ada pergeseran aktif
            if (_akumulasiSaatIni != 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saat ini jadwal sedang bergeser '
                        '${_akumulasiSaatIni > 0 ? "+$_akumulasiSaatIni" : "$_akumulasiSaatIni"} menit dari jam normal.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _kembalikanNormal,
                      child: const Text('Reset Normal'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Tidak ada jadwal untuk hari ini.'),
                ),
              )
            else ...[
              const Text(
                'Pilih keterlambatan masuk kelas:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Chips preset
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in [10, 15, 20, 30, 45])
                    ChoiceChip(
                      label: Text('+$m mnt'),
                      selected: _selisihPilihan == m,
                      onSelected: (v) {
                        if (v) setState(() => _selisihPilihan = m);
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Pilih Jam Awal Baru'),
                    onPressed: _pilihJamMulaiBaru,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Keterangan
              Text(
                'Menggeser jam awal sebanyak ${_selisihPilihan > 0 ? "+$_selisihPilihan" : "$_selisihPilihan"} menit. '
                'Semua jadwal berikutnya otomatis disesuaikan:',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),

              // Pratinjau Daftar Pergeseran
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final j = list[i];
                      final baru = tambahMenit(j.jam, j.menit, _selisihPilihan);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              formatJamMenit(j.jam, j.menit),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 14, color: Colors.black45),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                formatJamMenit(baru.jam, baru.menit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(AppKonstanta.navy),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                j.nama,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Terapkan
              Row(
                children: [
                  if (_akumulasiSaatIni != 0) ...[
                    OutlinedButton(
                      onPressed: _kembalikanNormal,
                      child: const Text('Reset Normal'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _terapkanPergeseran,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Terapkan (${_selisihPilihan > 0 ? "+$_selisihPilihan" : "$_selisihPilihan"} mnt)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppKonstanta.navy),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
