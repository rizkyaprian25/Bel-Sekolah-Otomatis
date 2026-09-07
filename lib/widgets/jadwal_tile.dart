import 'package:flutter/material.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/services/file_sound_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Satu baris jadwal: nama, jam, hari, info pengulangan, toggle, menu aksi.
class JadwalTile extends StatelessWidget {
  const JadwalTile({
    super.key,
    required this.jadwal,
    required this.onToggle,
    this.onEdit,
    this.onDuplikat,
    this.onHapus,
    this.sudahLewat = false,
    this.isBerikutnya = false,
  });

  final JadwalBel jadwal;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplikat;
  final VoidCallback? onHapus;
  final bool sudahLewat;
  final bool isBerikutnya;

  @override
  Widget build(BuildContext context) {
    final redup = !jadwal.aktif || sudahLewat;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isBerikutnya ? const Color(0xFFE8EFF7) : null,
      child: Opacity(
        opacity: redup ? 0.55 : 1.0,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: jadwal.aktif
                ? const Color(AppKonstanta.navy)
                : Colors.grey,
            child: const Icon(Icons.alarm, color: Colors.white, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  jadwal.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                jadwal.jamLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${jadwal.hariLabel}  |  '
              '${jadwal.jumlahPengulangan}x jeda ${jadwal.jedaDetik} dtk  |  '
              '${FileSoundService.label(jadwal.pathSuara)}',
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: jadwal.aktif, onChanged: onToggle),
              if (onEdit != null ||
                  onDuplikat != null ||
                  onHapus != null)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'duplikat') onDuplikat?.call();
                    if (v == 'hapus') onHapus?.call();
                  },
                  itemBuilder: (c) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (onDuplikat != null)
                      const PopupMenuItem(
                        value: 'duplikat',
                        child: Text('Duplikat'),
                      ),
                    if (onHapus != null)
                      const PopupMenuItem(
                        value: 'hapus',
                        child: Text('Hapus'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
