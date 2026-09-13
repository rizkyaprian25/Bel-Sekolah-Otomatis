import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/models/jp_generator_config.dart';
import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/services/database_service.dart';
import 'package:bel_sekolah_otomatis/services/file_sound_service.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';

class JadwalState {
  final List<JadwalBel> semua;
  final bool loading;
  final String? error;

  const JadwalState({
    this.semua = const [],
    this.loading = false,
    this.error,
  });

  JadwalState copyWith({
    List<JadwalBel>? semua,
    bool? loading,
    String? error,
  }) {
    return JadwalState(
      semua: semua ?? this.semua,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  List<JadwalBel> jadwalTanggal(DateTime tanggal) {
    final hasil = semua.where((j) => j.berlakuPada(tanggal)).toList();
    hasil.sort((a, b) {
      final c = a.jam.compareTo(b.jam);
      if (c != 0) return c;
      return a.menit.compareTo(b.menit);
    });
    return hasil;
  }
}

class JadwalNotifier extends StateNotifier<JadwalState> {
  JadwalNotifier(this.ref) : super(const JadwalState(loading: true)) {
    muat();
  }

  final Ref ref;

  Future<void> muat() async {
    state = state.copyWith(loading: true);
    try {
      final data = await DatabaseService.instance.getSemua();
      state = JadwalState(semua: data);
    } catch (e) {
      state = JadwalState(semua: state.semua, error: 'Gagal memuat: $e');
    }
  }

  Future<void> _simpanDanJadwalkan(List<JadwalBel> terbaru) async {
    state = state.copyWith(semua: terbaru);
    try {
      final atur = ref.read(pengaturanProvider);
      await SchedulerService.rescheduleDenganData(terbaru, atur);
    } catch (_) {}
  }

  /// Return null jika sukses, atau pesan error.
  Future<String?> tambah(JadwalBel jadwal) async {
    final err = jadwal.validasi();
    if (err != null) return err;
    try {
      await DatabaseService.instance.insert(jadwal);
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menyimpan: $e';
    }
  }

  Future<String?> terapkanJadwalJp(
    List<JadwalBel> listJadwal, {
    required List<int> daftarHari,
    bool gantiJadwalLama = true,
  }) async {
    if (listJadwal.isEmpty) return 'Daftar jadwal kosong';
    try {
      if (gantiJadwalLama) {
        await DatabaseService.instance.bersihkanJadwalHari(daftarHari);
      }
      await DatabaseService.instance.insertBatch(listJadwal);
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menerapkan jadwal: $e';
    }
  }

  Future<String?> toggleHari(int hari, bool aktif) async {
    try {
      final semua = await DatabaseService.instance.getSemua();
      final target = semua.where((j) => j.daftarHari.contains(hari)).toList();
      for (final j in target) {
        final baru = j.copyWith(aktif: aktif);
        await DatabaseService.instance.update(baru);
      }
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal mengubah status hari: $e';
    }
  }

  Future<String?> hapusHari(int hari) async {
    try {
      await DatabaseService.instance.bersihkanJadwalHari([hari]);
      await JpGeneratorConfig.hapusConfigHari(hari);
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menghapus jadwal hari: $e';
    }
  }

  Future<int> getPergeseranHari(int hari) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('keterlambatan_menit_$hari') ?? 0;
  }

  Future<String?> geserJadwalHari({
    required int hari,
    required int selisihMenit,
  }) async {
    try {
      await DatabaseService.instance.geserWaktuHari(
        hari: hari,
        selisihMenit: selisihMenit,
      );
      final prefs = await SharedPreferences.getInstance();
      final key = 'keterlambatan_menit_$hari';
      final lama = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, lama + selisihMenit);

      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menggeser jadwal: $e';
    }
  }

  Future<String?> resetPergeseranHari(int hari) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'keterlambatan_menit_$hari';
      final akumulasi = prefs.getInt(key) ?? 0;
      if (akumulasi != 0) {
        await DatabaseService.instance.geserWaktuHari(
          hari: hari,
          selisihMenit: -akumulasi,
        );
        await prefs.remove(key);
        final terbaru = await DatabaseService.instance.getSemua();
        await _simpanDanJadwalkan(terbaru);
      }
      return null;
    } catch (e) {
      return 'Gagal mereset jadwal: $e';
    }
  }

  Future<String?> ubahDenganGeserBerikutnya(
    JadwalBel jadwal, {
    required int selisihMenit,
  }) async {
    final err = jadwal.validasi();
    if (err != null) return err;
    try {
      await DatabaseService.instance.update(jadwal);
      if (selisihMenit != 0) {
        await DatabaseService.instance.geserWaktuSetelah(
          jadwalAwal: jadwal,
          selisihMenit: selisihMenit,
          daftarHari: jadwal.daftarHari,
        );
      }
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal mengubah: $e';
    }
  }

  Future<String?> ubah(JadwalBel jadwal) async {
    final err = jadwal.validasi();
    if (err != null) return err;
    try {
      final lama = await DatabaseService.instance.getById(jadwal.id);
      await DatabaseService.instance.update(jadwal);
      if (lama != null &&
          lama.pathSuara != jadwal.pathSuara &&
          lama.pathSuara.startsWith('file:')) {
        final masihDipakai = (await DatabaseService.instance.getSemua())
            .any((j) => j.id != jadwal.id && j.pathSuara == lama.pathSuara);
        if (!masihDipakai) {
          await FileSoundService.hapusJikaCustom(lama.pathSuara);
        }
      }
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal mengubah: $e';
    }
  }

  Future<String?> hapus(String id) async {
    try {
      final lama = await DatabaseService.instance.getById(id);
      await DatabaseService.instance.hapus(id);
      if (lama != null && lama.pathSuara.startsWith('file:')) {
        final masihDipakai = (await DatabaseService.instance.getSemua())
            .any((j) => j.pathSuara == lama.pathSuara);
        if (!masihDipakai) {
          await FileSoundService.hapusJikaCustom(lama.pathSuara);
        }
      }
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menghapus: $e';
    }
  }

  Future<void> toggle(String id, bool aktif) async {
    try {
      await DatabaseService.instance.setAktif(id, aktif);
      final terbaru = state.semua
          .map((j) => j.id == id ? j.copyWith(aktif: aktif) : j)
          .toList();
      await _simpanDanJadwalkan(terbaru);
    } catch (_) {
      await muat();
    }
  }

  Future<String?> duplikat(String id) async {
    try {
      final asal = await DatabaseService.instance.getById(id);
      if (asal == null) return 'Jadwal tidak ditemukan';
      final salinan = asal.duplikat();
      await DatabaseService.instance.insert(salinan);
      final terbaru = await DatabaseService.instance.getSemua();
      await _simpanDanJadwalkan(terbaru);
      return null;
    } catch (e) {
      return 'Gagal menduplikat: $e';
    }
  }
}

final jadwalProvider =
    StateNotifierProvider<JadwalNotifier, JadwalState>((ref) {
      return JadwalNotifier(ref);
    });

/// Jadwal yang berlaku hari ini (termasuk yang nonaktif, agar toggle
/// terlihat di dashboard). Urut waktu.
final jadwalHariIniProvider = Provider<List<JadwalBel>>((ref) {
  final semua = ref.watch(jadwalProvider).semua;
  final now = DateTime.now();
  final hasil = semua.where((j) => j.berlakuPada(now)).toList();
  hasil.sort((a, b) {
    final c = a.jam.compareTo(b.jam);
    if (c != 0) return c;
    return a.menit.compareTo(b.menit);
  });
  return hasil;
});
