import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';
import 'package:bel_sekolah_otomatis/services/database_service.dart';
import 'package:bel_sekolah_otomatis/services/notification_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

// Penjadwalan alarm exact via AndroidAlarmManager.
// Strategi: daftarkan one-shot untuk tiap kemunculan 7 hari ke depan.
// Dipanggil ulang setiap ada perubahan jadwal / pengaturan.
class SchedulerService {
  SchedulerService._();

  static const int hariKeDepan = 7;
  static const String _keyAlarmIds = 'jadwal_alarm_ids';

  /// Panggil sekali dari main() sebelum runApp.
  static Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<Pengaturan> bacaPengaturan() async {
    final prefs = await SharedPreferences.getInstance();
    return Pengaturan(
      modeSenyap: prefs.getBool(AppKonstanta.keyModeSenyap) ?? false,
      tanggalLibur:
          prefs.getStringList(AppKonstanta.keyTanggalLibur) ?? const [],
      manualSuara:
          prefs.getString(AppKonstanta.keyManualSuara) ??
          Pengaturan.suaraDefault(),
      manualVolume:
          prefs.getDouble(AppKonstanta.keyManualVolume) ?? 1.0,
    );
  }

  /// Jadwal ulang semua alarm dari data terbaru.
  static Future<void> rescheduleAll() async {
    final semua = await DatabaseService.instance.getSemua();
    final atur = await bacaPengaturan();
    await rescheduleDenganData(semua, atur);
  }

  static Future<void> rescheduleDenganData(
    List<JadwalBel> semua,
    Pengaturan atur,
  ) async {
    await _batalkanLama();
    if (atur.modeSenyap) {
      await _simpanIds(const []);
      return;
    }
    final now = DateTime.now();
    final ids = <int>[];

    for (final j in semua) {
      if (!j.aktif) continue;
      for (var offset = 0; offset < hariKeDepan; offset++) {
        final tanggal = DateTime(now.year, now.month, now.day).add(
          Duration(days: offset),
        );
        if (!j.berlakuPada(tanggal)) continue;
        if (atur.tanggalLibur.contains(tanggalKey(tanggal))) continue;
        final target = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          j.jam,
          j.menit,
        );
        // Toleransi 60 detik agar jadwal yang baru disimpan untuk menit
        // berjalan masih sempat dijadwalkan.
        if (target.isBefore(now.subtract(const Duration(seconds: 60)))) {
          continue;
        }
        final waktu = target.isBefore(now)
            ? now.add(const Duration(seconds: 2))
            : target;
        final alarmId = _alarmId(j.id, tanggal);
        ids.add(alarmId);
        try {
          await AndroidAlarmManager.oneShotAt(
            waktu,
            alarmId,
            alarmCallback,
            exact: true,
            wakeup: true,
            allowWhileIdle: true,
            rescheduleOnReboot: true,
            params: {'jadwalId': j.id},
          );
        } catch (_) {
          // Lanjut ke kemunculan lain walau satu gagal.
        }
      }
    }
    await _simpanIds(ids);
  }

  static int _alarmId(String jadwalId, DateTime tanggal) {
    return Object.hash(jadwalId, tanggalKey(tanggal)) & 0x7fffffff;
  }

  static Future<void> _batalkanLama() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lama = prefs.getStringList(_keyAlarmIds) ?? const [];
      for (final s in lama) {
        final id = int.tryParse(s);
        if (id != null) {
          try {
            await AndroidAlarmManager.cancel(id);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<void> _simpanIds(List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _keyAlarmIds,
        ids.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  /// Dipanggil dari main() tiap aplikasi dibuka. Jika HP habis restart
  /// (ditandai BootReceiver) atau alarm hilang, jadwalkan ulang.
  static Future<void> rescheduleJikaButuh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final butuh = prefs.getBool('butuh_reschedule_boot') ?? false;
      if (butuh) {
        await prefs.setBool('butuh_reschedule_boot', false);
        await rescheduleAll();
      }
    } catch (_) {}
  }

  static Future<void> batalSemua() async {
    await _batalkanLama();
    await _simpanIds(const []);
  }

  // --- Helper untuk UI (countdown bel berikutnya) ---

  static BelBerikutnya? cariBerikutnya(
    List<JadwalBel> semua,
    Pengaturan atur,
    DateTime now,
  ) {
    if (atur.modeSenyap) return null;
    BelBerikutnya? hasil;
    for (var offset = 0; offset < hariKeDepan; offset++) {
      final tanggal = DateTime(now.year, now.month, now.day).add(
        Duration(days: offset),
      );
      if (atur.tanggalLibur.contains(tanggalKey(tanggal))) continue;
      for (final j in semua) {
        if (!j.aktif) continue;
        if (!j.berlakuPada(tanggal)) continue;
        final target = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          j.jam,
          j.menit,
        );
        if (!target.isAfter(now)) continue;
        if (hasil == null || target.isBefore(hasil.waktu)) {
          hasil = BelBerikutnya(jadwal: j, waktu: target);
        }
      }
      if (hasil != null && offset > 1) break;
    }
    return hasil;
  }
}

class BelBerikutnya {
  final JadwalBel jadwal;
  final DateTime waktu;
  const BelBerikutnya({required this.jadwal, required this.waktu});
}

// Callback yang dijalankan Android di background isolate.
// Harus top-level + entry-point agar ditemukan setelah tree-shaking.
@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final jadwalId = params['jadwalId'] as String?;
    if (jadwalId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final modeSenyap =
        prefs.getBool(AppKonstanta.keyModeSenyap) ?? false;
    if (modeSenyap) return;

    final libur = prefs.getStringList(AppKonstanta.keyTanggalLibur) ?? const [];
    final now = DateTime.now();
    if (libur.contains(tanggalKey(now))) return;

    final db = await DatabaseService.openDb();
    List<Map<String, Object?>> rows = [];
    try {
      rows = await db.query(
        DatabaseService.tabelJadwal,
        where: 'id = ?',
        whereArgs: [jadwalId],
        limit: 1,
      );
    } finally {
      try {
        await db.close();
      } catch (_) {}
    }
    if (rows.isEmpty) return;
    final jadwal = JadwalBel.fromMap(rows.first);
    if (!jadwal.aktif) return;
    if (!jadwal.berlakuPada(now)) return;

    await NotificationService.tampilDiBackground(
      jadwal.nama,
      jadwal.jamLabel,
    );
    await AudioService.playInBackground(
      pathSuara: jadwal.pathSuara,
      volume: jadwal.volume,
      pengulangan: jadwal.jumlahPengulangan,
      jedaDetik: jadwal.jedaDetik,
    );
  } catch (_) {
    // Jangan lempar error dari background isolate.
  }
}
