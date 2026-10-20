import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Offline persistence for wardrobe items (Hive NoSQL, stored on device).
class WardrobeDb {
  static Box get box => Hive.box('wardrobe');
  static Box get settings => Hive.box('settings');

  static Future<Map<String, dynamic>> addItem({
    required String sourcePath,
    required String category,
    required List<int> hues,
    required List<String> tags,
    required double formality,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/wardrobe_images');
    await imgDir.create(recursive: true);
    final id = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(sourcePath).copy('${imgDir.path}/$id');

    final item = <String, dynamic>{
      'id': id,
      'imagePath': saved.path,
      'category': category,   // top | bottom | shoes | outerwear | accessory
      'hues': hues,           // dominant hue angles (0-360) from color extraction
      'tags': tags,           // raw on-device classifier labels
      'formality': formality, // 0.0 sporty .. 1.0 formal
      'wearCount': 0,
      'liked': null,          // null | true | false feedback for learning
      'createdAt': DateTime.now().toIso8601String(),
    };
    await box.put(id, item);
    return item;
  }

  static List<Map<String, dynamic>> items() =>
      box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));

  static Future<void> update(String id, Map<String, dynamic> patch) async {
    final item = Map<String, dynamic>.from(box.get(id) as Map);
    item.addAll(patch);
    await box.put(id, item);
  }

  static Future<void> delete(String id) async {
    final item = box.get(id);
    if (item != null) {
      try { File(item['imagePath'] as String).delete(); } catch (_) {}
    }
    await box.delete(id);
  }
}