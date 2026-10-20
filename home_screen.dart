import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vision_service.dart';
import '../services/wardrobe_db.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _vision = VisionService();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _items = WardrobeDb.items());

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return;

    String category = 'top';
    double formality = 0.5;
    List<int> hues = [0];
    List<String> tags = [];

    try {
      final a = await _vision.analyze(picked.path);
      category = a['category'] as String;
      formality = a['formality'] as double;
      hues = List<int>.from(a['hues'] as List);
      tags = List<String>.from(a['tags'] as List);
    } catch (_) {
      // Model not bundled yet -> let the user categorize manually.
      if (!mounted) return;
      final manual = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in ['top', 'bottom', 'shoes', 'outerwear', 'accessory'])
              ListTile(title: Text(c), onTap: () => Navigator.pop(ctx, c)),
          ]),
        ),
      );
      if (manual == null) return;
      category = manual;
    }

    await WardrobeDb.addItem(
      sourcePath: picked.path,
      category: category,
      hues: hues,
      tags: tags,
      formality: formality,
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Wardrobe')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPhoto,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add item'),
        ),
        body: _items.isEmpty
            ? const Center(child: Text('No items yet.\nUpload photos of your clothes!', textAlign: TextAlign.center))
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final it = _items[i];
                  return GestureDetector(
                    onLongPress: () async {
                      await WardrobeDb.delete(it['id'] as String);
                      _refresh();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.file(File(it['imagePath'] as String), fit: BoxFit.cover),
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('${it['category']}',
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      );
}
