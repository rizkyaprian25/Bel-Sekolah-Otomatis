import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
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
