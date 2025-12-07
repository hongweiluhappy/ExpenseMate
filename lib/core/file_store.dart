import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStore {
  static Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.json');
  }

  static Future<Map<String, dynamic>> read(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return {};
      final s = await f.readAsString();
      if (s.isEmpty) return {};
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static Future<void> write(String name, Map<String, dynamic> data) async {
    try {
      final f = await _file(name);
      await f.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      // Ignore write errors
    }
  }
}