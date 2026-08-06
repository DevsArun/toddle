import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, offline storage for artwork.
///
/// Two things are stored:
///  * an autosave snapshot per picture (tiny JSON, survives a crash)
///  * finished PNG artwork shown in "My Drawings"
class DrawingStorage extends ChangeNotifier {
  DrawingStorage._();

  static final DrawingStorage instance = DrawingStorage._();

  Directory? _dir;
  List<File> _saved = <File>[];

  List<File> get saved => List<File>.unmodifiable(_saved);

  Future<void> init() async {
    final Directory base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/drawings');
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_dir == null) return;
    final List<File> files = _dir!
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.png'))
        .toList()
      ..sort((File a, File b) =>
          b.statSync().modified.compareTo(a.statSync().modified));
    _saved = files;
    notifyListeners();
  }

  Future<File?> saveArtwork(Uint8List pngBytes) async {
    if (_dir == null) return null;
    final String name = 'art_${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File('${_dir!.path}/$name');
    await file.writeAsBytes(pngBytes, flush: true);
    await refresh();
    return file;
  }

  Future<void> delete(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
    await refresh();
  }

  // ------------------------------------------------------------- autosave

  String _autosaveKey(String pageId) => 'autosave_$pageId';

  Future<void> writeAutosave(String pageId, Map<String, dynamic> state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autosaveKey(pageId), jsonEncode(state));
  }

  Future<Map<String, dynamic>?> readAutosave(String pageId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_autosaveKey(pageId));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAutosave(String pageId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_autosaveKey(pageId));
  }
}
