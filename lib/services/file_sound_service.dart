import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Pilih file suara custom lalu salin ke direktori aplikasi agar path
// tetap valid setelah restart dan bisa dibaca background isolate.
class FileSoundService {
  FileSoundService._();

  static const _ekstensi = ['mp3', 'wav', 'm4a', 'ogg', 'aac'];

  static Future<String?> pilihDanSimpan() async {
    final hasil = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _ekstensi,
      allowMultiple: false,
      withData: false,
    );
    if (hasil == null || hasil.files.isEmpty) return null;
    final path = hasil.files.single.path;
    if (path == null) return null;
    return simpanKeAppDir(path);
  }

  static Future<String> simpanKeAppDir(String sumber) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'sounds_custom'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final namaAsli = p.basename(sumber);
    final namaAman =
        '${DateTime.now().millisecondsSinceEpoch}_$namaAsli';
    final tujuan = p.join(folder.path, namaAman);
    await File(sumber).copy(tujuan);
    return 'file:$tujuan';
  }

  static String label(String pathSuara) {
    for (final s in AppKonstanta.suaraBawaan) {
      if (s.id == pathSuara) return s.label;
    }
    if (pathSuara.startsWith('file:')) {
      return p.basename(pathSuara.replaceFirst('file:', ''));
    }
    return pathSuara;
  }

  static Future<bool> ada(String pathSuara) async {
    if (pathSuara.startsWith('assets:')) return true;
    final f = pathSuara.startsWith('file:')
        ? pathSuara.replaceFirst('file:', '')
        : pathSuara;
    return File(f).exists();
  }

  static Future<void> hapusJikaCustom(String pathSuara) async {
    if (!pathSuara.startsWith('file:')) return;
    try {
      final f = File(pathSuara.replaceFirst('file:', ''));
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
