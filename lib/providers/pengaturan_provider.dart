import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bel_sekolah_otomatis/models/pengaturan.dart';
import 'package:bel_sekolah_otomatis/providers/jadwal_provider.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

class PengaturanNotifier extends StateNotifier<Pengaturan> {
  PengaturanNotifier(this.ref) : super(const Pengaturan()) {
    muat();
  }

  final Ref ref;

  Future<void> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = Pengaturan(
        modeSenyap: prefs.getBool(AppKonstanta.keyModeSenyap) ?? false,
        tanggalLibur:
            prefs.getStringList(AppKonstanta.keyTanggalLibur) ?? const [],
        manualSuara:
            prefs.getString(AppKonstanta.keyManualSuara) ??
            Pengaturan.suaraDefault(),
        manualVolume:
            prefs.getDouble(AppKonstanta.keyManualVolume) ?? 1.0,
      );
    } catch (_) {}
  }

  Future<void> _simpan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppKonstanta.keyModeSenyap, state.modeSenyap);
      await prefs.setStringList(
        AppKonstanta.keyTanggalLibur,
        state.tanggalLibur,
      );
      await prefs.setString(AppKonstanta.keyManualSuara, state.manualSuara);
      await prefs.setDouble(
        AppKonstanta.keyManualVolume,
        state.manualVolume,
      );
    } catch (_) {}
  }

  Future<void> _simpanDanJadwalkan() async {
    await _simpan();
    try {
      final semua = ref.read(jadwalProvider).semua;
      await SchedulerService.rescheduleDenganData(semua, state);
    } catch (_) {}
  }

  Future<void> setModeSenyap(bool v) async {
    state = state.copyWith(modeSenyap: v);
    await _simpanDanJadwalkan();
  }

  /// Return null jika sukses, atau pesan error.
  Future<String?> tambahLibur(String tanggal) async {
    if (!Pengaturan.tanggalValid(tanggal)) {
      return 'Format tanggal harus YYYY-MM-DD';
    }
    if (state.tanggalLibur.contains(tanggal)) return 'Tanggal sudah ada';
    final baru = List.of(state.tanggalLibur)..add(tanggal);
    baru.sort();
    state = state.copyWith(tanggalLibur: baru);
    await _simpanDanJadwalkan();
    return null;
  }

  Future<void> hapusLibur(String tanggal) async {
    final baru = List.of(state.tanggalLibur)..remove(tanggal);
    state = state.copyWith(tanggalLibur: baru);
    await _simpanDanJadwalkan();
  }

  Future<void> setManualSuara(String pathSuara) async {
    state = state.copyWith(manualSuara: pathSuara);
    await _simpan();
  }

  Future<void> setManualVolume(double v) async {
    state = state.copyWith(manualVolume: v.clamp(0.0, 1.0));
    await _simpan();
  }

  Future<bool> izinAwalSudahDiminta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppKonstanta.keyIzinDiminta) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> tandaiIzinDiminta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppKonstanta.keyIzinDiminta, true);
    } catch (_) {}
  }
}

final pengaturanProvider =
    StateNotifierProvider<PengaturanNotifier, Pengaturan>((ref) {
      return PengaturanNotifier(ref);
    });
