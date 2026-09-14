import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';

// Memutar suara bel dengan pengulangan dan jeda.
// Dipakai dari UI (preview, bel manual) dan dari background isolate.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _player;
  bool _stopDiminta = false;
  int _sesi = 0;

  static AudioContext get audioContext => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
      );

  static Future<void> setupAudio() async {
    try {
      await AudioPlayer.global.setAudioContext(audioContext);
    } catch (e) {
      debugPrint('AudioService.setupAudio ERROR: $e');
    }
  }

  static Source resolveSource(String pathSuara) {
    if (pathSuara.startsWith('assets:')) {
      final file = pathSuara.replaceFirst('assets:', '');
      final clean = file.startsWith('sounds/') ? file : 'sounds/$file';
      return AssetSource(clean);
    }
    if (pathSuara.startsWith('assets/')) {
      final clean = pathSuara.replaceFirst('assets/', '');
      return AssetSource(clean);
    }
    if (pathSuara.startsWith('sounds/')) {
      return AssetSource(pathSuara);
    }
    if (pathSuara.startsWith('file:')) {
      return DeviceFileSource(pathSuara.replaceFirst('file:', ''));
    }
    return DeviceFileSource(pathSuara);
  }

  static bool fileAda(String pathSuara) {
    if (pathSuara.startsWith('assets:') ||
        pathSuara.startsWith('assets/') ||
        pathSuara.startsWith('sounds/')) {
      return true;
    }
    final p = pathSuara.startsWith('file:')
        ? pathSuara.replaceFirst('file:', '')
        : pathSuara;
    return File(p).existsSync();
  }

  /// Return null jika selesai tanpa error, atau pesan error.
  /// Error juga di-debugPrint agar terlihat di `flutter run` / logcat.
  Future<String?> playJadwal(JadwalBel jadwal) {
    return _mainkan(
      pathSuara: jadwal.pathSuara,
      volume: jadwal.volume,
      pengulangan: jadwal.jumlahPengulangan,
      jedaDetik: jadwal.jedaDetik,
    );
  }

  Future<String?> preview({
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

  Future<String?> belManual({
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

  Future<String?> _mainkan({
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
    try {
      await player.setAudioContext(audioContext);
    } catch (_) {}
    try {
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}

    final source = resolveSource(pathSuara);
    final ulang = pengulangan < 1 ? 1 : pengulangan;
    String? error;

    try {
      for (var i = 0; i < ulang; i++) {
        if (_stopDiminta || sesiIni != _sesi) break;
        debugPrint('AudioService: play $source (ulang ${i + 1}/$ulang)');

        final selesai = Completer<void>();
        final sub = player.onPlayerComplete.listen(
          (_) {
            if (!selesai.isCompleted) selesai.complete();
          },
          onDone: () {
            if (!selesai.isCompleted) selesai.complete();
          },
          onError: (Object e) {
            if (!selesai.isCompleted) selesai.completeError(e);
          },
          cancelOnError: false,
        );

        try {
          await player.play(source, volume: volume.clamp(0.0, 1.0));
          Duration? durasi;
          try {
            durasi = await player.getDuration();
          } catch (_) {}
          final timeoutDurasi = (durasi != null && durasi > Duration.zero)
              ? durasi + const Duration(seconds: 4)
              : const Duration(seconds: 15);
          await selesai.future.timeout(timeoutDurasi);
        } on TimeoutException {
          debugPrint('AudioService: timeout tunggu selesai, lanjut');
        } finally {
          await sub.cancel();
        }

        if (_stopDiminta || sesiIni != _sesi) break;
        if (i < ulang - 1 && jedaDetik > 0) {
          final ok = await _tungguBisaBatal(
            Duration(seconds: jedaDetik),
            sesiIni,
          );
          if (!ok) break;
        }
      }
    } catch (e) {
      error = 'Gagal memutar suara: $e';
      debugPrint('AudioService ERROR: $e');
    } finally {
      if (identical(_player, player)) _player = null;
      try {
        await player.dispose();
      } catch (_) {}
    }
    return error;
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

  static AudioPlayer? _bgPlayer;

  static Future<void> playInBackground({
    required String pathSuara,
    required double volume,
    required int pengulangan,
    required int jedaDetik,
  }) async {
    debugPrint('AudioService(bg): mulai $pathSuara x$pengulangan');
    try {
      await _bgPlayer?.stop();
      await _bgPlayer?.dispose();
    } catch (_) {}

    final player = AudioPlayer();
    _bgPlayer = player;
    try {
      try {
        await player.setAudioContext(audioContext);
      } catch (_) {}
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume.clamp(0.0, 1.0));
      final source = resolveSource(pathSuara);
      final ulang = pengulangan < 1 ? 1 : pengulangan;
      for (var i = 0; i < ulang; i++) {
        final selesai = Completer<void>();
        final sub = player.onPlayerComplete.listen(
          (_) {
            if (!selesai.isCompleted) selesai.complete();
          },
          onDone: () {
            if (!selesai.isCompleted) selesai.complete();
          },
          onError: (Object e) {
            if (!selesai.isCompleted) selesai.completeError(e);
          },
          cancelOnError: false,
        );

        try {
          await player.play(source, volume: volume.clamp(0.0, 1.0));
          Duration? durasi;
          try {
            durasi = await player.getDuration();
          } catch (_) {}
          final timeoutDurasi = (durasi != null && durasi > Duration.zero)
              ? durasi + const Duration(seconds: 4)
              : const Duration(seconds: 15);
          await selesai.future.timeout(timeoutDurasi);
        } on TimeoutException {
          debugPrint('AudioService(bg): timeout tunggu selesai, lanjut');
        } finally {
          await sub.cancel();
        }

        if (i < ulang - 1 && jedaDetik > 0) {
          await Future.delayed(Duration(seconds: jedaDetik));
        }
      }
      debugPrint('AudioService(bg): selesai');
    } catch (e) {
      debugPrint('AudioService(bg) ERROR: $e');
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
