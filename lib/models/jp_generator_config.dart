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
    this.suaraMasuk = 'assets:bel_panjang.wav',
    this.suaraPergantian = 'assets:bel_klasik.wav',
    this.suaraIstirahat = 'assets:bel_digital.wav',
    this.suaraPulang = 'assets:bel_panjang.wav',
    this.volume = 1.0,
    this.jumlahPengulangan = 3,
    this.jedaDetik = 3,
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
      suaraMasuk: suaraMasuk ?? this.suaraMasuk,
      suaraPergantian: suaraPergantian ?? this.suaraPergantian,
      suaraIstirahat: suaraIstirahat ?? this.suaraIstirahat,
      suaraPulang: suaraPulang ?? this.suaraPulang,
      volume: volume ?? this.volume,
      jumlahPengulangan: jumlahPengulangan ?? this.jumlahPengulangan,
      jedaDetik: jedaDetik ?? this.jedaDetik,
    );
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
      istirahat2Aktif: false,
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
      istirahat2Aktif: false,
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
          pathSuara: suaraMasuk,
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
          pathSuara: suaraMasuk,
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
            pathSuara: suaraPergantian,
          ),
        );
      } else if (i > 1) {
        final nama = baruSelesaiIstirahat
            ? 'Bel Masuk Selesai Istirahat (JP $i)'
            : 'Bel Pergantian Jam (Masuk JP $i)';
        list.add(
          ItemPratinjauJp(
            nama: nama,
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.jp,
            keterangan: 'Durasi JP $durasiJpMenit menit',
            pathSuara: baruSelesaiIstirahat ? suaraMasuk : suaraPergantian,
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
            pathSuara: suaraIstirahat,
          ),
        );
        current = current.add(Duration(minutes: durasiIstirahat1Menit));
        baruSelesaiIstirahat = true;
      }

      // Cek Istirahat 2 (opsional, misal Dzuhur)
      if (istirahat2Aktif && setelahJpKe2 == i && i < jumlahJp) {
        list.add(
          ItemPratinjauJp(
            nama: 'Bel Istirahat 2 / Dzuhur',
            jam: current.hour,
            menit: current.minute,
            tipe: TipeItemJp.istirahat,
            keterangan: 'Istirahat di luar JP ($durasiIstirahat2Menit menit)',
            pathSuara: suaraIstirahat,
          ),
        );
        current = current.add(Duration(minutes: durasiIstirahat2Menit));
        baruSelesaiIstirahat = true;
      }
    }

    // 3. Bel Pulang Sekolah
    list.add(
      ItemPratinjauJp(
        nama: 'Bel Pulang Sekolah',
        jam: current.hour,
        menit: current.minute,
        tipe: TipeItemJp.pulang,
        keterangan: 'Semua jam pelajaran telah selesai',
        pathSuara: suaraPulang,
      ),
    );

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
