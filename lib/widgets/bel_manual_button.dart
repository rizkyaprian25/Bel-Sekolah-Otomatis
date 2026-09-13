import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';

// Tombol lebar untuk membunyikan bel manual kapan saja.
// Tekan sekali bunyi, tekan lagi berhenti.
class BelManualButton extends ConsumerStatefulWidget {
  const BelManualButton({super.key});

  @override
  ConsumerState<BelManualButton> createState() => _BelManualButtonState();
}

class _BelManualButtonState extends ConsumerState<BelManualButton> {
  bool _bunyi = false;

  Future<void> _toggle() async {
    if (_bunyi) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _bunyi = false);
      return;
    }
    final atur = ref.read(pengaturanProvider);
    setState(() => _bunyi = true);
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
      if (mounted) setState(() => _bunyi = false);
    }
  }

  @override
  void dispose() {
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _toggle,
          icon: Icon(_bunyi ? Icons.stop : Icons.notifications_active),
          label: Text(
            _bunyi ? 'Hentikan Bel Manual' : 'Bunyikan Bel Manual',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _bunyi
                ? const Color(0xFFC62828)
                : const Color(0xFF1A3A5F),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
