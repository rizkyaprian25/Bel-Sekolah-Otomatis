import 'package:flutter/material.dart';

import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Pilih hari 1-7 (Senin-Minggu). Tampil sebagai chip + tombol cepat.
class HariPicker extends StatelessWidget {
  const HariPicker({
    super.key,
    required this.terpilih,
    required this.onChanged,
  });

  final List<int> terpilih;
  final ValueChanged<List<int>> onChanged;

  void _toggle(int hari) {
    final baru = List.of(terpilih);
    if (baru.contains(hari)) {
      baru.remove(hari);
    } else {
      baru.add(hari);
    }
    baru.sort();
    onChanged(baru);
  }

  void _isi(List<int> hari) => onChanged(List.of(hari)..sort());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var h = 1; h <= 7; h++)
              FilterChip(
                label: Text(AppKonstanta.namaHariSingkat[h]),
                selected: terpilih.contains(h),
                onSelected: (_) => _toggle(h),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton(
              onPressed: () => _isi([1, 2, 3, 4, 5]),
              child: const Text('Senin-Jumat'),
            ),
            TextButton(
              onPressed: () => _isi([1, 2, 3, 4, 5, 6, 7]),
              child: const Text('Setiap hari'),
            ),
            TextButton(
              onPressed: () => _isi(const []),
              child: const Text('Bersihkan'),
            ),
          ],
        ),
      ],
    );
  }
}
