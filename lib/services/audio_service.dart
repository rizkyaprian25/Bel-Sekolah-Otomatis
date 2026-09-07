import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';

// Memutar suara bel dengan pengulangan dan jeda.
// Dipakai dari UI (preview, bel manual) dan dari background isolate.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _player;
  bool _stopDiminta = false;
  int _sesi = 0;

  static Source resolveSource(String pathSuara) {
    if (pathSuara.startsWith('assets:')) {
      final file = pathSuara.replaceFirst('assets:', '');
      return AssetSource('sounds/$file');
    }
    if (pathSuara.startsWith('file:')) {
      return DeviceFileSource(pathSuara.replaceFirst('file:', ''));
    }
    return DeviceFileSource(pathSuara);
  }

  static bool fileAda(String pathSuara) {
    if (pathSuara.startsWith('assets:')) return true;
    final p = pathSuara.startsWith('file:')
        ? pathSuara.replaceFirst('file:', '')
        : pathSuara;
    return File(p).existsSync();
  }

  Future<void> playJadwal(JadwalBel jadwal) {
    return _mainkan(
      pathSuara: jadwal.pathSuara,
      volume: jadwal.volume,
      pengulangan: jadwal.jumlahPengulangan,
      jedaDetik: jadwal.jedaDetik,
    );
  }

  Future<void> preview({
    required String pathSuara,
    required double volume,
    required int pengulangan,
    required int jedaDetik,
  }) {
    return _mainkan(
      pathSuara: pathSuara,
      volume: volume,
      pengulangan: pengulangan,
      jedaDetik: jedaDetik,
    );
  }

  Future<void> belManual({
    required String pathSuara,
    required double volume,
  }) {
    return _mainkan(
      pathSuara: pathSuara,
      volume: volume,
      pengulangan: 2,
      jedaDetik: 2,
    );
  }

  Future<void> _mainkan({
    required String pathSuara,
    required double volume,
    required int pengulangan,
    required int jedaDetik,
  }) async {
    await stop();
    _stopDiminta = false;
    final sesiIni = ++_sesi;

    final player = AudioPlayer();
    _player = player;
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(volume.clamp(0.0, 1.0));

    final source = resolveSource(pathSuara);
    final ulang = pengulangan < 1 ? 1 : pengulangan;

    try {
      for (var i = 0; i < ulang; i++) {
        if (_stopDiminta || sesiIni != _sesi) break;
        await player.play(source, volume: volume.clamp(0.0, 1.0));
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
          onTimeout: () {},
        );
        if (_stopDiminta || sesiIni != _sesi) break;
        if (i < ulang - 1 && jedaDetik > 0) {
          final ok = await _tungguBisaBatal(
            Duration(seconds: jedaDetik),
            sesiIni,
          );
          if (!ok) break;
        }
      }
    } catch (_) {
      // Abaikan error audio agar tidak crash UI / callback.
    } finally {
      if (identical(_player, player)) _player = null;
      await player.dispose();
    }
  }

  /// Tunggu yang bisa dibatalkan via stop(). Dibagi per 200ms.
  Future<bool> _tungguBisaBatal(Duration total, int sesiIni) async {
    var sisa = total.inMilliseconds;
    const langkah = 200;
    while (sisa > 0) {
      if (_stopDiminta || sesiIni != _sesi) return false;
      final t = sisa >= langkah ? langkah : sisa;
      await Future.delayed(Duration(milliseconds: t));
      sisa -= t;
    }
    return !_stopDiminta && sesiIni == _sesi;
  }

  Future<void> stop() async {
    _stopDiminta = true;
    _sesi++;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  bool get sedangBunyi => _player != null;

  // --- Dipakai dari background isolate (alarm callback) ---

  static Future<void> playInBackground({
    required String pathSuara,
    required double volume,
    required int pengulangan,
    required int jedaDetik,
  }) async {
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume.clamp(0.0, 1.0));
      final source = resolveSource(pathSuara);
      final ulang = pengulangan < 1 ? 1 : pengulangan;
      for (var i = 0; i < ulang; i++) {
        await player.play(source, volume: volume.clamp(0.0, 1.0));
        await player.onPlayerComplete.first.timeout(
          const Duration(seconds: 30),
          onTimeout: () {},
        );
        if (i < ulang - 1 && jedaDetik > 0) {
          await Future.delayed(Duration(seconds: jedaDetik));
        }
      }
    } catch (_) {
      // Abaikan agar callback alarm tidak crash.
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
