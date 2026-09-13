import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/models/jp_generator_config.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';
import 'package:bel_sekolah_otomatis/widgets/hari_picker.dart';

class JpGeneratorScreen extends ConsumerStatefulWidget {
  const JpGeneratorScreen({super.key});

  @override
  ConsumerState<JpGeneratorScreen> createState() => _JpGeneratorScreenState();
}

class _JpGeneratorScreenState extends ConsumerState<JpGeneratorScreen> {
  // Hari
  List<int> _daftarHari = [1, 2, 3, 4]; // Default Senin - Kamis

  // Jam Mulai
  int _jamMulai = 7;
  int _menitMulai = 0;

  // Kegiatan Awal (Upacara / Literasi)
  bool _adaKegiatanAwal = false;
  final TextEditingController _namaKegiatanAwalCtrl =
      TextEditingController(text: 'Upacara Bendera');
  int _durasiKegiatanAwal = 45;

  // Jam Pelajaran (JP)
  int _jumlahJp = 9;
  int _durasiJp = 35;

  // Istirahat 1
  bool _istirahat1Aktif = true;
  int _setelahJp1 = 4;
  int _durasiIstirahat1 = 30;

  // Istirahat 2 (Opsional / Dzuhur)
  bool _istirahat2Aktif = false;
  int _setelahJp2 = 7;
  int _durasiIstirahat2 = 30;

  // Suara Bel
  String _suaraMasuk = 'assets:bel_panjang.wav';
  String _suaraPergantian = 'assets:bel_klasik.wav';
  String _suaraIstirahat = 'assets:bel_digital.wav';
  String _suaraPulang = 'assets:bel_panjang.wav';

  // Opsi ganti jadwal lama
  bool _gantiJadwalLama = true;

  // Sedang memutar preview suara
  String? _suaraPreviewId;

  @override
  void dispose() {
    _namaKegiatanAwalCtrl.dispose();
    AudioService.instance.stop();
    super.dispose();
  }

  JpGeneratorConfig _buatConfig() {
    return JpGeneratorConfig(
      daftarHari: _daftarHari,
      jamMulai: _jamMulai,
      menitMulai: _menitMulai,
      adaKegiatanAwal: _adaKegiatanAwal,
      namaKegiatanAwal: _namaKegiatanAwalCtrl.text.trim().isEmpty
          ? 'Upacara'
          : _namaKegiatanAwalCtrl.text.trim(),
      durasiKegiatanAwalMenit: _durasiKegiatanAwal,
      jumlahJp: _jumlahJp,
      durasiJpMenit: _durasiJp,
      istirahat1Aktif: _istirahat1Aktif,
      setelahJpKe1: _setelahJp1,
      durasiIstirahat1Menit: _durasiIstirahat1,
      istirahat2Aktif: _istirahat2Aktif,
      setelahJpKe2: _setelahJp2,
      durasiIstirahat2Menit: _durasiIstirahat2,
      suaraMasuk: _suaraMasuk,
      suaraPergantian: _suaraPergantian,
      suaraIstirahat: _suaraIstirahat,
      suaraPulang: _suaraPulang,
    );
  }

  void _terapkanPreset(String jenis) {
    setState(() {
      if (jenis == 'senin_upacara') {
        _daftarHari = [1];
        _adaKegiatanAwal = true;
        _namaKegiatanAwalCtrl.text = 'Upacara Bendera';
        _durasiKegiatanAwal = 45;
        _jumlahJp = 9;
        _durasiJp = 35;
        _istirahat1Aktif = true;
        _setelahJp1 = 4;
        _durasiIstirahat1 = 30;
        _istirahat2Aktif = false;
      } else if (jenis == 'senin_kamis') {
        _daftarHari = [1, 2, 3, 4];
        _adaKegiatanAwal = false;
        _jumlahJp = 9;
        _durasiJp = 35;
        _istirahat1Aktif = true;
        _setelahJp1 = 4;
        _durasiIstirahat1 = 30;
        _istirahat2Aktif = false;
      } else if (jenis == 'jumat') {
        _daftarHari = [5];
        _adaKegiatanAwal = false;
        _jumlahJp = 5;
        _durasiJp = 30;
        _istirahat1Aktif = true;
        _setelahJp1 = 3;
        _durasiIstirahat1 = 25;
        _istirahat2Aktif = false;
      }
    });
  }

  Future<void> _pilihJamMulai() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _jamMulai, minute: _menitMulai),
    );
    if (hasil != null && mounted) {
      setState(() {
        _jamMulai = hasil.hour;
        _menitMulai = hasil.minute;
      });
    }
  }

  Future<void> _togglePreviewSuara(String pathSuara) async {
    if (_suaraPreviewId == pathSuara) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _suaraPreviewId = null);
      return;
    }
    await AudioService.instance.stop();
    setState(() => _suaraPreviewId = pathSuara);
    try {
      final err = await AudioService.instance.preview(
        pathSuara: pathSuara,
        volume: 1.0,
        pengulangan: 1,
        jedaDetik: 0,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _suaraPreviewId = null);
    }
  }

  Future<void> _simpanSemua() async {
    if (_daftarHari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu hari berlaku!')),
      );
      return;
    }

    final config = _buatConfig();
    final listJadwal = config.generateJadwal();

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Terapkan Jadwal Pelajaran?'),
        content: Text(
          'Akan membuat ${listJadwal.length} jadwal bel otomatis untuk '
          'hari yang dipilih.\n\n'
          '${_gantiJadwalLama ? "Jadwal lama pada hari tersebut akan digantikan secara bersih." : "Jadwal baru akan ditambahkan tanpa menghapus jadwal lama."}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Ya, Terapkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    final err = await ref.read(jadwalProvider.notifier).terapkanJadwalJp(
          listJadwal,
          daftarHari: _daftarHari,
          gantiJadwalLama: _gantiJadwalLama,
        );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menerapkan ${listJadwal.length} jadwal pelajaran!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _buatConfig();
    final pratinjau = config.buatPratinjau();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Jam Pelajaran (JP)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Penjelasan
          Card(
            color: Colors.blue.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(AppKonstanta.navy)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atur 1 kali untuk menyusun seluruh jam pelajaran, '
                      'bel istirahat, dan bel pulang secara otomatis.',
                      style: TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preset Cepat
          const Text(
            'Pilihan Cepat (Preset)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.school, size: 18),
                  label: const Text('Senin (Upacara + 9 JP)'),
                  onPressed: () => _terapkanPreset('senin_upacara'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Senin-Kamis (9 JP @ 35m)'),
                  onPressed: () => _terapkanPreset('senin_kamis'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.access_time, size: 18),
                  label: const Text('Jumat (5 JP @ 30m)'),
                  onPressed: () => _terapkanPreset('jumat'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bagian 1: Hari Berlaku
          _kartuBagian(
            title: '1. Hari Berlaku',
            icon: Icons.date_range,
            child: HariPicker(
              terpilih: _daftarHari,
              onChanged: (hari) => setState(() => _daftarHari = hari),
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 2: Jam Mulai Sekolah & Kegiatan Awal
          _kartuBagian(
            title: '2. Jam Masuk & Kegiatan Awal',
            icon: Icons.alarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Jam Masuk Sekolah'),
                  subtitle: Text(
                    'Bel pertama berbunyi pukul ${formatJamMenit(_jamMulai, _menitMulai)}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: _pilihJamMulai,
                    child: Text(formatJamMenit(_jamMulai, _menitMulai)),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ada Upacara / Kegiatan Awal'),
                  subtitle: const Text(
                    'Misal upacara bendera hari Senin atau pembiasaan literasi sebelum JP 1',
                  ),
                  value: _adaKegiatanAwal,
                  onChanged: (v) => setState(() => _adaKegiatanAwal = v),
                ),
                if (_adaKegiatanAwal) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaKegiatanAwalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kegiatan',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Durasi Kegiatan: '),
                      const Spacer(),
                      DropdownButton<int>(
                        value: _durasiKegiatanAwal,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 Menit')),
                          DropdownMenuItem(value: 30, child: Text('30 Menit')),
                          DropdownMenuItem(value: 40, child: Text('40 Menit')),
                          DropdownMenuItem(value: 45, child: Text('45 Menit')),
                          DropdownMenuItem(value: 60, child: Text('60 Menit')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _durasiKegiatanAwal = v);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 3: Jam Pelajaran (JP)
          _kartuBagian(
            title: '3. Jam Pelajaran (JP)',
            icon: Icons.timer,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jumlah JP:',
                      style: TextStyle(fontSize: 15),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _jumlahJp > 1
                              ? () => setState(() => _jumlahJp--)
                              : null,
                        ),
                        Text(
                          '$_jumlahJp JP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _jumlahJp < 12
                              ? () => setState(() => _jumlahJp++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Durasi 1 JP:',
                      style: TextStyle(fontSize: 15),
                    ),
                    DropdownButton<int>(
                      value: _durasiJp,
                      items: const [
                        DropdownMenuItem(value: 25, child: Text('25 Menit')),
                        DropdownMenuItem(value: 30, child: Text('30 Menit')),
                        DropdownMenuItem(value: 35, child: Text('35 Menit')),
                        DropdownMenuItem(value: 40, child: Text('40 Menit')),
                        DropdownMenuItem(value: 45, child: Text('45 Menit')),
                        DropdownMenuItem(value: 50, child: Text('50 Menit')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _durasiJp = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 4: Bel Istirahat di Luar JP
          _kartuBagian(
            title: '4. Bel Istirahat (Di Luar JP)',
            icon: Icons.coffee,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bel istirahat berbunyi di luar jam pelajaran. '
                  'Setelah istirahat selesai, bel akan memanggil siswa masuk kembali '
                  'dan JP berikutnya dimulai.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                // Istirahat 1
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Istirahat 1',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        value: _istirahat1Aktif,
                        onChanged: (v) => setState(() => _istirahat1Aktif = v),
                      ),
                      if (_istirahat1Aktif) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Setelah JP ke:'),
                            DropdownButton<int>(
                              value: _setelahJp1.clamp(1, _jumlahJp - 1),
                              items: [
                                for (var i = 1; i < _jumlahJp; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text('Setelah JP $i'),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _setelahJp1 = v);
                                }
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Durasi Istirahat:'),
                            DropdownButton<int>(
                              value: _durasiIstirahat1,
                              items: const [
                                DropdownMenuItem(
                                    value: 15, child: Text('15 Menit')),
                                DropdownMenuItem(
                                    value: 20, child: Text('20 Menit')),
                                DropdownMenuItem(
                                    value: 25, child: Text('25 Menit')),
                                DropdownMenuItem(
                                    value: 30, child: Text('30 Menit')),
                                DropdownMenuItem(
                                    value: 40, child: Text('40 Menit')),
                                DropdownMenuItem(
                                    value: 45, child: Text('45 Menit')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _durasiIstirahat1 = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Istirahat 2 (Opsional / Dzuhur)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Istirahat 2 (Sholat Dzuhur / Makan)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        value: _istirahat2Aktif,
                        onChanged: (v) => setState(() => _istirahat2Aktif = v),
                      ),
                      if (_istirahat2Aktif) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Setelah JP ke:'),
                            DropdownButton<int>(
                              value: _setelahJp2.clamp(
                                (_setelahJp1 + 1).clamp(1, _jumlahJp - 1),
                                _jumlahJp - 1,
                              ),
                              items: [
                                for (var i = _setelahJp1 + 1; i < _jumlahJp; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text('Setelah JP $i'),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _setelahJp2 = v);
                                }
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Durasi Istirahat 2:'),
                            DropdownButton<int>(
                              value: _durasiIstirahat2,
                              items: const [
                                DropdownMenuItem(
                                    value: 20, child: Text('20 Menit')),
                                DropdownMenuItem(
                                    value: 30, child: Text('30 Menit')),
                                DropdownMenuItem(
                                    value: 40, child: Text('40 Menit')),
                                DropdownMenuItem(
                                    value: 45, child: Text('45 Menit')),
                                DropdownMenuItem(
                                    value: 60, child: Text('60 Menit')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _durasiIstirahat2 = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 5: Suara Bel
          _kartuBagian(
            title: '5. Suara Bel',
            icon: Icons.volume_up,
            child: Column(
              children: [
                _barisPilihSuara(
                  label: 'Bel Masuk Sekolah',
                  nilai: _suaraMasuk,
                  onChanged: (s) => setState(() => _suaraMasuk = s),
                ),
                const Divider(),
                _barisPilihSuara(
                  label: 'Bel Pergantian JP',
                  nilai: _suaraPergantian,
                  onChanged: (s) => setState(() => _suaraPergantian = s),
                ),
                const Divider(),
                _barisPilihSuara(
                  label: 'Bel Istirahat',
                  nilai: _suaraIstirahat,
                  onChanged: (s) => setState(() => _suaraIstirahat = s),
                ),
                const Divider(),
                _barisPilihSuara(
                  label: 'Bel Pulang Sekolah',
                  nilai: _suaraPulang,
                  onChanged: (s) => setState(() => _suaraPulang = s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bagian 6: Pratinjau Jadwal yang Dihasilkan
          _kartuBagian(
            title: '6. Pratinjau Rangkaian Jadwal (${pratinjau.length} Bel)',
            icon: Icons.list_alt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gantikan jadwal lama pada hari terpilih'),
                  subtitle: const Text(
                    'Membersihkan jadwal lama di hari yang dipilih agar tidak dobel',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _gantiJadwalLama,
                  onChanged: (v) =>
                      setState(() => _gantiJadwalLama = v ?? true),
                ),
                const Divider(),
                for (var i = 0; i < pratinjau.length; i++) ...[
                  _itemTimeline(pratinjau[i], i == pratinjau.length - 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Aksi Terapkan
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _simpanSemua,
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Terapkan Jadwal (${pratinjau.length} Bel)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppKonstanta.navy),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _kartuBagian({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(AppKonstanta.navy)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(AppKonstanta.navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _barisPilihSuara({
    required String label,
    required String nilai,
    required ValueChanged<String> onChanged,
  }) {
    final sedangMain = _suaraPreviewId == nilai;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: nilai,
                items: [
                  for (final s in AppKonstanta.suaraBawaan)
                    DropdownMenuItem(value: s.id, child: Text(s.label)),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: sedangMain ? 'Hentikan' : 'Dengar suara',
          icon: Icon(
            sedangMain ? Icons.stop_circle : Icons.play_circle_outline,
            color: sedangMain ? Colors.red : const Color(AppKonstanta.navy),
            size: 28,
          ),
          onPressed: () => _togglePreviewSuara(nilai),
        ),
      ],
    );
  }

  Widget _itemTimeline(ItemPratinjauJp item, bool isTerakhir) {
    Color warnaBadge;
    IconData iconBadge;

    switch (item.tipe) {
      case TipeItemJp.masuk:
        warnaBadge = Colors.green;
        iconBadge = Icons.login;
        break;
      case TipeItemJp.upacara:
        warnaBadge = Colors.orange;
        iconBadge = Icons.flag;
        break;
      case TipeItemJp.jp:
        warnaBadge = Colors.blue;
        iconBadge = Icons.menu_book;
        break;
      case TipeItemJp.istirahat:
        warnaBadge = Colors.amber.shade800;
        iconBadge = Icons.coffee;
        break;
      case TipeItemJp.pulang:
        warnaBadge = Colors.red;
        iconBadge = Icons.logout;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blueGrey.shade200),
            ),
            child: Text(
              item.jamLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(iconBadge, size: 18, color: warnaBadge),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.keterangan,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
