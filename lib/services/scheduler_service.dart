import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/services/audio_service.dart';
import 'package:bel_sekolah_otomatis/services/database_service.dart';
import 'package:bel_sekolah_otomatis/services/notification_service.dart';
import 'package:bel_sekolah_otomatis/utils/async_lock.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

// Penjadwalan alarm exact via AndroidAlarmManager.
// Strategi: daftarkan one-shot untuk tiap kemunculan 7 hari ke depan.
// Menggunakan AsyncLock agar reschedule berurutan dan bebas dari race condition / alarm hantu.
class SchedulerService {
  SchedulerService._();

  static const int hariKeDepan = 7;
  static const String _keyAlarmIds = 'jadwal_alarm_ids';
  static final AsyncLock _schedulerLock = AsyncLock();

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

  /// Membatalkan secara eksplisit semua alarm milik satu jadwal (misal saat dihapus)
  static Future<void> batalkanAlarmJadwal(String jadwalId) async {
    final now = DateTime.now();
    for (var offset = 0; offset < hariKeDepan + 1; offset++) {
      final tanggal = DateTime(now.year, now.month, now.day).add(
        Duration(days: offset),
      );
      final id = _alarmId(jadwalId, tanggal);
      try {
        await AndroidAlarmManager.cancel(id);
      } catch (_) {}
    }
  }

  static Future<void> rescheduleDenganData(
    List<JadwalBel> semua,
    Pengaturan atur,
  ) async {
    return _schedulerLock.synchronized(() async {
      await _batalkanLama();
      if (atur.modeSenyap) {
        await _simpanIds(const []);
        await perbaruiStatusNotifikasi(daftarJadwal: semua);
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
            final ok = await AndroidAlarmManager.oneShotAt(
              waktu,
              alarmId,
              alarmCallback,
              exact: true,
              wakeup: true,
              allowWhileIdle: true,
              rescheduleOnReboot: true,
              params: {'jadwalId': j.id},
            );
            debugPrint('AndroidAlarmManager.oneShotAt [$alarmId] ${j.nama} @ $waktu => $ok');
          } catch (e) {
            debugPrint('AndroidAlarmManager.oneShotAt [$alarmId] ERROR: $e');
          }
        }
      }
      await _simpanIds(ids);
      await perbaruiStatusNotifikasi(daftarJadwal: semua);
    });
  }

  static int _alarmId(String jadwalId, DateTime tanggal) {
    final key = '$jadwalId-${tanggalKey(tanggal)}';
    var hash = 0x811c9dc5;
    for (var i = 0; i < key.length; i++) {
      hash = (hash ^ key.codeUnitAt(i)) * 0x01000193;
      hash &= 0x7fffffff;
    }
    return hash;
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
        final waktu = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          j.jam,
          j.menit,
        );
        if (waktu.isBefore(now)) continue;
        if (hasil == null || waktu.isBefore(hasil.waktu)) {
          hasil = BelBerikutnya(jadwal: j, waktu: waktu);
        }
      }
    }
    return hasil;
  }

  /// Memperbarui notifikasi status persisten (bergaya media player).
  /// Aman dipanggil dari UI isolate atau background isolate tanpa menutup DB.
  static Future<void> perbaruiStatusNotifikasi({
    List<JadwalBel>? daftarJadwal,
    bool diBackground = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusAktif =
          prefs.getBool(AppKonstanta.keyNotifStatusAktif) ?? true;
      if (!statusAktif) {
        if (diBackground) {
          await NotificationService.hapusNotifikasiStatusDiBackground();
        } else {
          await NotificationService.instance.hapusNotifikasiStatus();
        }
        return;
      }

      final atur = await bacaPengaturan();
      if (atur.modeSenyap) {
        const judul = '🔔 Bel Sekolah: Mode Senyap';
        const pesan = 'Suara bel dinonaktifkan sementara';
        if (diBackground) {
          await NotificationService.perbaruiNotifikasiStatusDiBackground(
            judul: judul,
            pesan: pesan,
            subteks: 'Mode Senyap',
          );
        } else {
          await NotificationService.instance.perbaruiNotifikasiStatus(
            judul: judul,
            pesan: pesan,
            subteks: 'Mode Senyap',
          );
        }
        return;
      }

      final List<JadwalBel> semua = daftarJadwal ??
          await DatabaseService.instance.getSemua();

      final now = DateTime.now();
      final berikutnya = cariBerikutnya(semua, atur, now);

      String judul = '🔔 Bel Sekolah Aktif';
      String pesan = 'Sistem memantau jadwal di latar belakang';
      String? subteks;

      if (berikutnya != null) {
        final bedaHari = berikutnya.waktu.day - now.day;
        final hariStr = bedaHari == 0
            ? 'Hari Ini'
            : bedaHari == 1
                ? 'Besok'
                : AppKonstanta.namaHari[berikutnya.waktu.weekday];

        judul = '🔔 Bel Berikutnya: ${berikutnya.jadwal.nama}';
        pesan = 'Pukul ${berikutnya.jadwal.jamLabel} ($hariStr)';
        subteks = 'Jadwal $hariStr';
      } else {
        judul = '🔔 Bel Sekolah: Tidak Ada Jadwal';
        pesan = 'Semua bel hari ini telah selesai atau sedang libur';
        subteks = 'Siaga';
      }

      if (diBackground) {
        await NotificationService.perbaruiNotifikasiStatusDiBackground(
          judul: judul,
          pesan: pesan,
          subteks: subteks,
        );
      } else {
        await NotificationService.instance.perbaruiNotifikasiStatus(
          judul: judul,
          pesan: pesan,
          subteks: subteks,
        );
      }
    } catch (e) {
      debugPrint('perbaruiStatusNotifikasi error: $e');
    }
  }

  static const String _keyTerakhirBunyi = 'jadwal_terakhir_bunyi';
  static String? _memoriTerakhirBunyi;

  static Future<bool> sudahBunyi(String key) async {
    if (_memoriTerakhirBunyi == key) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tersimpan = prefs.getString(_keyTerakhirBunyi);
      if (tersimpan == key) {
        _memoriTerakhirBunyi = key;
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> catatSudahBunyi(String key) async {
    _memoriTerakhirBunyi = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTerakhirBunyi, key);
    } catch (_) {}
  }

  /// Pemicu bel saat aplikasi sedang aktif di layar (foreground stream).
  static Future<void> periksaDanBunyikanDiForeground(
    JadwalBel jadwal,
    String key,
  ) async {
    if (await sudahBunyi(key)) return;
    await catatSudahBunyi(key);
    debugPrint('SchedulerService(fg): Bunyikan ${jadwal.nama}');
    try {
      await NotificationService.instance.tampilBel(
        jadwal.nama,
        jadwal.jamLabel,
      );
      await AudioService.instance.playJadwal(jadwal);
      await perbaruiStatusNotifikasi();
    } catch (e) {
      debugPrint('SchedulerService(fg) ERROR: $e');
    }
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
    debugPrint('alarmCallback: id=$alarmId params=$params');
    final jadwalId = params['jadwalId'] as String?;
    if (jadwalId == null) {
      debugPrint('alarmCallback: tanpa jadwalId, abaikan');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final modeSenyap =
        prefs.getBool(AppKonstanta.keyModeSenyap) ?? false;
    if (modeSenyap) return;

    final libur = prefs.getStringList(AppKonstanta.keyTanggalLibur) ?? const [];
    final now = DateTime.now();
    if (libur.contains(tanggalKey(now))) return;

    // Baca data jadwal dari database TANPA menutup koneksi database (no db.close)
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      DatabaseService.tabelJadwal,
      where: 'id = ?',
      whereArgs: [jadwalId],
      limit: 1,
    );
    if (rows.isEmpty) {
      debugPrint('alarmCallback: jadwal $jadwalId sudah dihapus dari DB, abaikan');
      return;
    }
    final jadwal = JadwalBel.fromMap(rows.first);
    if (!jadwal.aktif) {
      debugPrint('alarmCallback: jadwal nonaktif, abaikan');
      return;
    }
    if (!jadwal.berlakuPada(now)) {
      debugPrint('alarmCallback: tidak berlaku hari ini, abaikan');
      return;
    }

    // Kunci deduplikasi global berdasarkan jam & menit bel sekolah.
    // Menjamin TIDAK ADA dua bel yang berbunyi bersamaan saling bertabrakan pada menit yang sama.
    final key = 'bel_${tanggalKey(now)}_${jadwal.jam}_${jadwal.menit}';
    if (await SchedulerService.sudahBunyi(key)) {
      debugPrint('alarmCallback: bel $key sudah berbunyi (foreground/alarm lain), lewati');
      return;
    }
    await SchedulerService.catatSudahBunyi(key);

    debugPrint('alarmCallback: bunyikan ${jadwal.nama}');

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

    // Perbarui status notifikasi media bar ke bel berikutnya
    await SchedulerService.perbaruiStatusNotifikasi(diBackground: true);
  } catch (e) {
    // Jangan lempar error dari background isolate, cukup catat.
    debugPrint('alarmCallback ERROR: $e');
  }
}
