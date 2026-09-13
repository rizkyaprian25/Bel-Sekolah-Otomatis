import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

enum TipeItemJp {
  masuk,
  upacara,
  jp,
  istirahat,
  pulang,
}

class ItemPratinjauJp {
  final String nama;
  final int jam;
  final int menit;
  final TipeItemJp tipe;
  final String keterangan;
  final String pathSuara;

  const ItemPratinjauJp({
    required this.nama,
    required this.jam,
    required this.menit,
    required this.tipe,
    required this.keterangan,
    required this.pathSuara,
  });

  String get jamLabel => formatJamMenit(jam, menit);
}

class JpGeneratorConfig {
  final List<int> daftarHari;
  final int jamMulai;
  final int menitMulai;

  // Kegiatan awal (misal Upacara hari Senin atau Literasi)
  final bool adaKegiatanAwal;
  final String namaKegiatanAwal;
  final int durasiKegiatanAwalMenit;

  // Jam Pelajaran (JP)
  final int jumlahJp;
  final int durasiJpMenit;

  // Istirahat di luar JP
  final bool istirahat1Aktif;
  final int setelahJpKe1;
  final int durasiIstirahat1Menit;

  final bool istirahat2Aktif;
  final int setelahJpKe2;
  final int durasiIstirahat2Menit;

  // Khusus Hari Jumat: Bel Pengambilan MBG Jam 11:00
  final bool mbgJumatAktif;

  // Mode Suara AI Otomatis
  final bool gunakanSuaraAi;

  // Suara & Pengulangan
  final String suaraMasuk;
  final String suaraPergantian;
  final String suaraIstirahat;
  final String suaraPulang;
  final double volume;
  final int jumlahPengulangan;
  final int jedaDetik;

  const JpGeneratorConfig({
    required this.daftarHari,
    this.jamMulai = 7,
    this.menitMulai = 0,
    this.adaKegiatanAwal = false,
    this.namaKegiatanAwal = 'Upacara Bendera',
    this.durasiKegiatanAwalMenit = 45,
    this.jumlahJp = 9,
    this.durasiJpMenit = 35,
    this.istirahat1Aktif = true,
    this.setelahJpKe1 = 4,
    this.durasiIstirahat1Menit = 30,
    this.istirahat2Aktif = false,
    this.setelahJpKe2 = 7,
    this.durasiIstirahat2Menit = 30,
    this.mbgJumatAktif = false,
    this.gunakanSuaraAi = true,
    this.suaraMasuk = 'assets:ai_masuk_jp1.mp3',
    this.suaraPergantian = 'assets:ai_jam_ke_2.mp3',
    this.suaraIstirahat = 'assets:ai_istirahat.mp3',
    this.suaraPulang = 'assets:ai_pulang.mp3',
    this.volume = 1.0,
    this.jumlahPengulangan = 2,
    this.jedaDetik = 2,
  });

  JpGeneratorConfig copyWith({
    List<int>? daftarHari,
    int? jamMulai,
    int? menitMulai,
    bool? adaKegiatanAwal,
    String? namaKegiatanAwal,
    int? durasiKegiatanAwalMenit,
    int? jumlahJp,
    int? durasiJpMenit,
    bool? istirahat1Aktif,
    int? setelahJpKe1,
    int? durasiIstirahat1Menit,
    bool? istirahat2Aktif,
    int? setelahJpKe2,
    int? durasiIstirahat2Menit,
    bool? mbgJumatAktif,
    bool? gunakanSuaraAi,
    String? suaraMasuk,
    String? suaraPergantian,
    String? suaraIstirahat,
    String? suaraPulang,
    double? volume,
    int? jumlahPengulangan,
    int? jedaDetik,
  }) {
    return JpGeneratorConfig(
      daftarHari: daftarHari ?? this.daftarHari,
      jamMulai: jamMulai ?? this.jamMulai,
      menitMulai: menitMulai ?? this.menitMulai,
      adaKegiatanAwal: adaKegiatanAwal ?? this.adaKegiatanAwal,
      namaKegiatanAwal: namaKegiatanAwal ?? this.namaKegiatanAwal,
      durasiKegiatanAwalMenit:
          durasiKegiatanAwalMenit ?? this.durasiKegiatanAwalMenit,
      jumlahJp: jumlahJp ?? this.jumlahJp,
      durasiJpMenit: durasiJpMenit ?? this.durasiJpMenit,
      istirahat1Aktif: istirahat1Aktif ?? this.istirahat1Aktif,
      setelahJpKe1: setelahJpKe1 ?? this.setelahJpKe1,
      durasiIstirahat1Menit:
          durasiIstirahat1Menit ?? this.durasiIstirahat1Menit,
      istirahat2Aktif: istirahat2Aktif ?? this.istirahat2Aktif,
      setelahJpKe2: setelahJpKe2 ?? this.setelahJpKe2,
      durasiIstirahat2Menit:
          durasiIstirahat2Menit ?? this.durasiIstirahat2Menit,
      mbgJumatAktif: mbgJumatAktif ?? this.mbgJumatAktif,
      gunakanSuaraAi: gunakanSuaraAi ?? this.gunakanSuaraAi,
      suaraMasuk: suaraMasuk ?? this.suaraMasuk,
      suaraPergantian: suaraPergantian ?? this.suaraPergantian,
      suaraIstirahat: suaraIstirahat ?? this.suaraIstirahat,
      suaraPulang: suaraPulang ?? this.suaraPulang,
      volume: volume ?? this.volume,
      jumlahPengulangan: jumlahPengulangan ?? this.jumlahPengulangan,
      jedaDetik: jedaDetik ?? this.jedaDetik,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daftarHari': daftarHari,
      'jamMulai': jamMulai,
      'menitMulai': menitMulai,
      'adaKegiatanAwal': adaKegiatanAwal,
      'namaKegiatanAwal': namaKegiatanAwal,
      'durasiKegiatanAwalMenit': durasiKegiatanAwalMenit,
      'jumlahJp': jumlahJp,
      'durasiJpMenit': durasiJpMenit,
      'istirahat1Aktif': istirahat1Aktif,
      'setelahJpKe1': setelahJpKe1,
      'durasiIstirahat1Menit': durasiIstirahat1Menit,
      'istirahat2Aktif': istirahat2Aktif,
      'setelahJpKe2': setelahJpKe2,
      'durasiIstirahat2Menit': durasiIstirahat2Menit,
      'mbgJumatAktif': mbgJumatAktif,
      'gunakanSuaraAi': gunakanSuaraAi,
      'suaraMasuk': suaraMasuk,
      'suaraPergantian': suaraPergantian,
      'suaraIstirahat': suaraIstirahat,
      'suaraPulang': suaraPulang,
      'volume': volume,
      'jumlahPengulangan': jumlahPengulangan,
      'jedaDetik': jedaDetik,
    };
  }

  factory JpGeneratorConfig.fromJson(Map<String, dynamic> json) {
    return JpGeneratorConfig(
      daftarHari: (json['daftarHari'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4],
      jamMulai: json['jamMulai'] as int? ?? 7,
      menitMulai: json['menitMulai'] as int? ?? 0,
      adaKegiatanAwal: json['adaKegiatanAwal'] as bool? ?? false,
      namaKegiatanAwal:
          json['namaKegiatanAwal'] as String? ?? 'Upacara Bendera',
      durasiKegiatanAwalMenit:
          json['durasiKegiatanAwalMenit'] as int? ?? 45,
      jumlahJp: json['jumlahJp'] as int? ?? 9,
      durasiJpMenit: json['durasiJpMenit'] as int? ?? 35,
      istirahat1Aktif: json['istirahat1Aktif'] as bool? ?? true,
      setelahJpKe1: json['setelahJpKe1'] as int? ?? 4,
      durasiIstirahat1Menit: json['durasiIstirahat1Menit'] as int? ?? 30,
      istirahat2Aktif: json['istirahat2Aktif'] as bool? ?? false,
      setelahJpKe2: json['setelahJpKe2'] as int? ?? 7,
      durasiIstirahat2Menit: json['durasiIstirahat2Menit'] as int? ?? 30,
      mbgJumatAktif: json['mbgJumatAktif'] as bool? ?? false,
      gunakanSuaraAi: json['gunakanSuaraAi'] as bool? ?? true,
      suaraMasuk:
          json['suaraMasuk'] as String? ?? 'assets:ai_masuk_jp1.mp3',
      suaraPergantian:
          json['suaraPergantian'] as String? ?? 'assets:ai_jam_ke_2.mp3',
      suaraIstirahat:
          json['suaraIstirahat'] as String? ?? 'assets:ai_istirahat.mp3',
      suaraPulang: json['suaraPulang'] as String? ?? 'assets:ai_pulang.mp3',
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      jumlahPengulangan: json['jumlahPengulangan'] as int? ?? 2,
      jedaDetik: json['jedaDetik'] as int? ?? 2,
    );
  }

  static Future<void> simpanConfigHari(
      int hari, JpGeneratorConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'jp_config_hari_$hari', jsonEncode(config.toJson()));
  }

  static Future<JpGeneratorConfig?> bacaConfigHari(int hari) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('jp_config_hari_$hari');
    if (data == null) return null;
    try {
      return JpGeneratorConfig.fromJson(
          jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> hapusConfigHari(int hari) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jp_config_hari_$hari');
  }

  /// Preset bawaan untuk kemudahan konfigurasi
  factory JpGeneratorConfig.seninKamisDefault() {
    return const JpGeneratorConfig(
      daftarHari: [1, 2, 3, 4],
      jumlahJp: 9,
      durasiJpMenit: 35,
      istirahat1Aktif: true,
      setelahJpKe1: 4,
      durasiIstirahat1Menit: 30,
      istirahat2Aktif: true,
      setelahJpKe2: 7,
      durasiIstirahat2Menit: 30,
    );
  }

  factory JpGeneratorConfig.seninUpacaraDefault() {
    return const JpGeneratorConfig(
      daftarHari: [1],
      adaKegiatanAwal: true,
      namaKegiatanAwal: 'Upacara Bendera',
      durasiKegiatanAwalMenit: 45,
      jumlahJp: 9,
      durasiJpMenit: 35,
      istirahat1Aktif: true,
      setelahJpKe1: 4,
      durasiIstirahat1Menit: 30,
      istirahat2Aktif: true,
      setelahJpKe2: 7,
      durasiIstirahat2Menit: 30,
    );
  }

  factory JpGeneratorConfig.jumatDefault() {
    return const JpGeneratorConfig(
      daftarHari: [5],
      jumlahJp: 5,
      durasiJpMenit: 30,
      istirahat1Aktif: true,
      setelahJpKe1: 3,
      durasiIstirahat1Menit: 25,
      istirahat2Aktif: false,
      mbgJumatAktif: true,
    );
  }

  /// Menghitung urutan waktu dan detail pratinjau
  List<ItemPratinjauJp> buatPratinjau() {
    final list = <ItemPratinjauJp>[];
    var current = DateTime(2026, 1, 1, jamMulai, menitMulai);

    // 1. Bel Masuk / Kegiatan Awal
    if (adaKegiatanAwal) {
      list.add(
        ItemPratinjauJp(
          nama: 'Bel Masuk - $namaKegiatanAwal',
          jam: current.hour,
          menit: current.minute,
          tipe: TipeItemJp.upacara,
          keterangan: 'Durasi $durasiKegiatanAwalMenit menit',
          pathSuara: gunakanSuaraAi ? 'assets:ai_masuk_jp1.mp3' : suaraMasuk,
        ),
      );
      current = current.add(Duration(minutes: durasiKegiatanAwalMenit));
    } else {
      list.add(
        ItemPratinjauJp(
          nama: 'Bel Masuk Sekolah (JP 1)',
          jam: current.hour,
          menit: current.minute,
          tipe: TipeItemJp.masuk,
          keterangan: 'Mulai kegiatan belajar JP 1',
          pathSuara: gunakanSuaraAi ? 'assets:ai_masuk_jp1.mp3' : suaraMasuk,
        ),
      );
    }

    bool baruSelesaiIstirahat = false;

    // 2. Loop tiap JP
    for (var i = 1; i <= jumlahJp; i++) {
      if (adaKegiatanAwal && i == 1) {
        list.add(
          ItemPratinjauJp(
            nama: 'Bel Masuk JP 1',
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.jp,
            keterangan: 'Mulai JP 1 setelah $namaKegiatanAwal',
            pathSuara: gunakanSuaraAi ? 'assets:ai_masuk_jp1.mp3' : suaraMasuk,
          ),
        );
      } else if (i > 1) {
        final nama = baruSelesaiIstirahat
            ? 'Bel Masuk Selesai Istirahat (JP $i)'
            : 'Bel Pergantian Jam (Masuk JP $i)';

        String pathSuaraJp;
        if (baruSelesaiIstirahat) {
          if (gunakanSuaraAi) {
            pathSuaraJp = i == 5
                ? 'assets:ai_selesai_istirahat_jp5.mp3'
                : 'assets:ai_selesai_istirahat_umum.mp3';
          } else {
            pathSuaraJp = suaraMasuk;
          }
        } else {
          if (gunakanSuaraAi) {
            pathSuaraJp = i <= 10 ? 'assets:ai_jam_ke_$i.mp3' : suaraPergantian;
          } else {
            pathSuaraJp = suaraPergantian;
          }
        }

        list.add(
          ItemPratinjauJp(
            nama: nama,
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.jp,
            keterangan: 'Durasi JP $durasiJpMenit menit',
            pathSuara: pathSuaraJp,
          ),
        );
      }

      baruSelesaiIstirahat = false;
      // Waktu selama pelajaran JP i berlangsung
      current = current.add(Duration(minutes: durasiJpMenit));

      // Cek Istirahat 1
      if (istirahat1Aktif && setelahJpKe1 == i && i < jumlahJp) {
        list.add(
          ItemPratinjauJp(
            nama: 'Bel Istirahat 1',
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.istirahat,
            keterangan: 'Istirahat di luar JP ($durasiIstirahat1Menit menit)',
            pathSuara:
                gunakanSuaraAi ? 'assets:ai_istirahat.mp3' : suaraIstirahat,
          ),
        );
        current = current.add(Duration(minutes: durasiIstirahat1Menit));
        baruSelesaiIstirahat = true;
      }

      // Cek Istirahat 2 (MBG / Dzuhur)
      if (istirahat2Aktif && setelahJpKe2 == i && i < jumlahJp) {
        list.add(
          ItemPratinjauJp(
            nama: 'Bel Istirahat 2 (Pengambilan MBG)',
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.istirahat,
            keterangan:
                'Istirahat ($durasiIstirahat2Menit menit) • Pengambilan MBG',
            pathSuara: gunakanSuaraAi
                ? 'assets:ai_istirahat2_mbg.mp3'
                : suaraIstirahat,
          ),
        );
        current = current.add(Duration(minutes: durasiIstirahat2Menit));
        baruSelesaiIstirahat = true;
      }
    }

    // 3. Bel Pengambilan MBG Khusus Jumat (Pukul 11:00)
    if (mbgJumatAktif && daftarHari.contains(5)) {
      list.add(
        ItemPratinjauJp(
          nama: 'Bel Pengambilan MBG (Jumat)',
          jam: 11,
          menit: 0,
          tipe: TipeItemJp.istirahat,
          keterangan: 'Pengambilan MBG hari Jumat tepat pukul 11:00',
          pathSuara:
              gunakanSuaraAi ? 'assets:ai_mbg_jumat.mp3' : suaraIstirahat,
        ),
      );
    }

    // 4. Bel Pulang Sekolah
    list.add(
      ItemPratinjauJp(
        nama: 'Bel Pulang Sekolah',
        jam: current.hour,
        menit: current.minute,
        tipe: TipeItemJp.pulang,
        keterangan: 'Semua jam pelajaran telah selesai',
        pathSuara: gunakanSuaraAi ? 'assets:ai_pulang.mp3' : suaraPulang,
      ),
    );

    // Urutkan jadwal secara kronologis berdasarkan jam & menit
    list.sort((a, b) => (a.jam * 60 + a.menit).compareTo(b.jam * 60 + b.menit));

    return list;
  }

  /// Menghasilkan List JadwalBel siap simpan
  List<JadwalBel> generateJadwal() {
    final pratinjau = buatPratinjau();
    final hasil = <JadwalBel>[];

    for (final item in pratinjau) {
      hasil.add(
        JadwalBel.baru(
          nama: item.nama,
          jam: item.jam,
          menit: item.menit,
          daftarHari: daftarHari,
          pathSuara: item.pathSuara,
          volume: volume,
          jumlahPengulangan: jumlahPengulangan,
          jedaDetik: jedaDetik,
        ),
      );
    }
    return hasil;
  }
}
