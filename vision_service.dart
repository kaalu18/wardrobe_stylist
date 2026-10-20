import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// 100% on-device "vision": MobileNet image labeling + dominant-color palette.
/// Nothing ever leaves the phone, which is what makes offline mode possible.
class VisionService {
  Interpreter? _it;
  List<String> _labels = [];

  static const _categoryKeywords = {
    'top': ['shirt', 'jersey', 'sweater', 'cardigan', 'blouse', 'tank', 'tee'],
    'bottom': ['jean', 'denim', 'trouser', 'pants', 'shorts', 'skirt', 'legging'],
    'shoes': ['shoe', 'sneaker', 'boot', 'sandal', 'loafer', 'clog', 'running shoe', 'oxford'],
    'outerwear': ['jacket', 'coat', 'parka', 'windbreaker', 'blazer', 'suit'],
    'accessory': ['handbag', 'backpack', 'purse', 'hat', 'cap', 'sunglass', 'tie', 'belt', 'scarf'],
  };

  Future<void> init() async {
    if (_it != null) return;
    final bytes = await rootBundle.load('assets/mobilenet_v1_1.0_224_quant.tflite');
    _it = Interpreter.fromBuffer(bytes.buffer.asUint8List());
    _labels = (await rootBundle.loadString('assets/labels.txt'))
        .split('
').where((e) => e.trim().isNotEmpty).toList();
  }

  Future<Map<String, dynamic>> analyze(String path) async {
    await init();
    final raw = img.decodeImage(await File(path).readAsBytes())!;
    final im = img.copyResize(raw, width: 224, height: 224);

    // uint8 quantized MobileNet input [1,224,224,3]
    final input = [
      List.generate(224, (y) => List.generate(224, (x) {
        final p = im.getPixel(x, y);
        return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
      }))
    ];
    final output = [List<int>.filled(_labels.length, 0)];
    _it!.run(input, output);
    final scores = output[0];
    final best = scores.indexOf(scores.reduce(max));
    final label = _labels[best].toLowerCase();

    String category = 'accessory';
    for (final e in _categoryKeywords.entries) {
      if (e.value.any((k) => label.contains(k))) { category = e.key; break; }
    }

    double formality = 0.5;
    if (label.contains('suit') || label.contains('blazer') || label.contains('bow tie') || label.contains('loafer')) {
      formality = 0.9;
    } else if (label.contains('jersey') || label.contains('shorts') || label.contains('sneaker') ||
        label.contains('tank') || label.contains('running')) {
      formality = 0.2;
    }

    // Dominant hues for color-harmony scoring.
    final hues = <int>[];
    try {
      final pal = await PaletteGenerator.fromImageProvider(
        FileImage(File(path)), size: const Size(64, 64), maximumColorCount: 5);
      for (final c in pal.paletteColors) {
        final hsv = HSVColor.fromColor(c.color);
        if (hsv.saturation > 0.25 && hsv.value > 0.2) hues.add(hsv.hue.toInt());
      }
    } catch (_) {}
    if (hues.isEmpty) hues.add(0);

    return {
      'category': category,
      'formality': formality,
      'hues': hues,
      'tags': [label.replaceAll(RegExp(r'^\d+\s+'), '').trim()],
      'label': label,
    };
  }
}
