import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

// Izin yang diminta saat pertama buka aplikasi:
// notifikasi, exact alarm (Android 12+), dan battery exemption.
class PermissionService {
  PermissionService._();

  static Future<bool> _minta(Permission p) async {
    if (!Platform.isAndroid) return true;
    final status = await p.status;
    if (status.isGranted) return true;
    final hasil = await p.request();
    return hasil.isGranted || hasil.isLimited;
  }

  /// Minta semua izin awal. Return true jika yang kritis (notifikasi)
  /// granted. Exact alarm dan battery bersifat best-effort.
  static Future<StatusIzin> mintaIzinAwal() async {
    final notif = await _minta(Permission.notification);
    final exact = await _minta(Permission.scheduleExactAlarm);
    final baterai = await _minta(Permission.ignoreBatteryOptimizations);
    return StatusIzin(
      notifikasi: notif,
      exactAlarm: exact,
      baterai: baterai,
    );
  }

  static Future<StatusIzin> cekStatus() async {
    if (!Platform.isAndroid) {
      return const StatusIzin(
        notifikasi: true,
        exactAlarm: true,
        baterai: true,
      );
    }
    return StatusIzin(
      notifikasi: await Permission.notification.isGranted,
      exactAlarm: await Permission.scheduleExactAlarm.isGranted,
      baterai: await Permission.ignoreBatteryOptimizations.isGranted,
    );
  }

  static Future<void> bukaPengaturan() async {
    await openAppSettings();
  }
}

class StatusIzin {
  final bool notifikasi;
  final bool exactAlarm;
  final bool baterai;

  const StatusIzin({
    required this.notifikasi,
    required this.exactAlarm,
    required this.baterai,
  });

  bool get semuaOk => notifikasi && exactAlarm && baterai;

  String get ringkasan {
    final kurang = <String>[];
    if (!notifikasi) kurang.add('Notifikasi');
    if (!exactAlarm) kurang.add('Alarm Tepat Waktu');
    if (!baterai) kurang.add('Battery Exemption');
    if (kurang.isEmpty) return 'Semua izin granted';
    return 'Belum granted: ${kurang.join(', ')}';
  }
}
