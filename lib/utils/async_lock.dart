import 'dart:async';

/// Utilitas antrean asinkron (mutex) sederhana tanpa dependensi luar.
/// Menjamin operasi asinkron dieksekusi secara berurutan (FIFO) satu per satu.
class AsyncLock {
  Future<void>? _last;

  Future<T> synchronized<T>(Future<T> Function() computation) async {
    final prev = _last;
    final completer = Completer<void>();
    _last = completer.future;

    if (prev != null) {
      try {
        await prev;
      } catch (_) {}
    }

    try {
      return await computation();
    } finally {
      completer.complete();
    }
  }
}
