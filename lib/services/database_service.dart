import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:bel_sekolah_otomatis/models/jadwal_bel.dart';
import 'package:bel_sekolah_otomatis/utils/waktu.dart';

// Akses SQLite untuk tabel jadwal.
// Dipakai dari UI isolate maupun background isolate (alarm callback),
// jadi open database lewat method static yang sama.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const String tabelJadwal = 'jadwal';
  static const int versiDb = 1;

  Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null) return db;
    return _db = await openDb();
  }

  static Future<String> dbPath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'bel_sekolah.db');
  }

  static Future<Database> openDb() async {
    final path = await dbPath();
    return openDatabase(
      path,
      version: versiDb,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tabelJadwal (
            id TEXT PRIMARY KEY,
            nama TEXT NOT NULL,
            jam INTEGER NOT NULL,
            menit INTEGER NOT NULL,
            daftarHari TEXT NOT NULL,
            pengulangan INTEGER NOT NULL DEFAULT 3,
            jedaDetik INTEGER NOT NULL DEFAULT 5,
            pathSuara TEXT NOT NULL DEFAULT '',
            volume REAL NOT NULL DEFAULT 1.0,
            aktif INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_jadwal_waktu ON $tabelJadwal (jam, menit)',
        );
      },
    );
  }

  Future<void> insert(JadwalBel j) async {
    final db = await database;
    await db.insert(
      tabelJadwal,
      j.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBatch(List<JadwalBel> list) async {
    final db = await database;
    final batch = db.batch();
    for (final j in list) {
      batch.insert(
        tabelJadwal,
        j.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Menghapus hari [daftarHariTarget] dari jadwal yang ada.
  /// Jika jadwal hanya berlaku pada hari tersebut, hapus baris.
  /// Jika berlaku pada hari lain juga, update daftarHari agar hari lain tidak hilang.
  Future<void> bersihkanJadwalHari(List<int> daftarHariTarget) async {
    final semua = await getSemua();
    final db = await database;
    final batch = db.batch();

    for (final j in semua) {
      final sisaHari = j.daftarHari
          .where((h) => !daftarHariTarget.contains(h))
          .toList();
      if (sisaHari.isEmpty) {
        batch.delete(tabelJadwal, where: 'id = ?', whereArgs: [j.id]);
      } else if (sisaHari.length != j.daftarHari.length) {
        final updated = j.copyWith(daftarHari: sisaHari);
        batch.update(
          tabelJadwal,
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [j.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  /// Menggeser waktu seluruh jadwal pada [hari] sebesar [selisihMenit].
  Future<void> geserWaktuHari({
    required int hari,
    required int selisihMenit,
  }) async {
    if (selisihMenit == 0) return;
    final semua = await getSemua();
    final db = await database;
    final batch = db.batch();

    for (final j in semua) {
      if (j.daftarHari.contains(hari)) {
        final baru = tambahMenit(j.jam, j.menit, selisihMenit);
        batch.update(
          tabelJadwal,
          {'jam': baru.jam, 'menit': baru.menit},
          where: 'id = ?',
          whereArgs: [j.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  /// Menggeser jadwal yang berada SETELAH [jadwalAwal] pada [daftarHari] sebesar [selisihMenit].
  Future<void> geserWaktuSetelah({
    required JadwalBel jadwalAwal,
    required int selisihMenit,
    required List<int> daftarHari,
  }) async {
    if (selisihMenit == 0) return;
    final semua = await getSemua();
    final menitAwal = jadwalAwal.jam * 60 + jadwalAwal.menit;
    final db = await database;
    final batch = db.batch();

    for (final j in semua) {
      if (j.id == jadwalAwal.id) continue;
      final adaHariSama = j.daftarHari.any((h) => daftarHari.contains(h));
      if (!adaHariSama) continue;

      final menitJ = j.jam * 60 + j.menit;
      if (menitJ >= menitAwal) {
        final baru = tambahMenit(j.jam, j.menit, selisihMenit);
        batch.update(
          tabelJadwal,
          {'jam': baru.jam, 'menit': baru.menit},
          where: 'id = ?',
          whereArgs: [j.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(JadwalBel j) async {
    final db = await database;
    await db.update(
      tabelJadwal,
      j.toMap(),
      where: 'id = ?',
      whereArgs: [j.id],
    );
  }

  Future<void> hapus(String id) async {
    final db = await database;
    await db.delete(tabelJadwal, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JadwalBel>> getSemua() async {
    final db = await database;
    final rows = await db.query(
      tabelJadwal,
      orderBy: 'jam ASC, menit ASC, nama ASC',
    );
    return rows.map(JadwalBel.fromMap).toList();
  }

  Future<JadwalBel?> getById(String id) async {
    final db = await database;
    final rows = await db.query(
      tabelJadwal,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return JadwalBel.fromMap(rows.first);
  }

  Future<void> setAktif(String id, bool aktif) async {
    final db = await database;
    await db.update(
      tabelJadwal,
      {'aktif': aktif ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Jadwal aktif yang berlaku pada [tanggal] (filter hari),
  /// urut waktu. Tanggal libur dan mode senyap dicek di layer atas
  /// (provider / scheduler) agar service tetap murni data.
  Future<List<JadwalBel>> getJadwalTanggal(DateTime tanggal) async {
    final semua = await getSemua();
    final hasil = semua
        .where((j) => j.aktif && j.berlakuPada(tanggal))
        .toList();
    hasil.sort((a, b) {
      final c = a.jam.compareTo(b.jam);
      if (c != 0) return c;
      return a.menit.compareTo(b.menit);
    });
    return hasil;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
