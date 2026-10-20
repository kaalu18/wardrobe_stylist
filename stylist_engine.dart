import 'dart:math';

/// Rule-based + color-theory outfit scorer.
/// v1 uses color harmony (complementary / analogous / triadic), formality vs
/// occasion, weather, and "least recently worn" variety. Your like/dislike
/// feedback is stored per item so v2 can learn weights from it.
class StylistEngine {
  static const _occasionFormality = {
    'gym': 0.10, 'casual': 0.35, 'date': 0.65, 'party': 0.55, 'office': 0.80,
  };

  static double _hueDist(int a, int b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  static double _pairScore(int h1, int h2) {
    final d = _hueDist(h1, h2);
    if (d >= 150 && d <= 210) return 2.0; // complementary
    if (d <= 45) return 1.5;              // analogous / monochrome
    if (d >= 80 && d <= 120) return 1.0;  // triadic-ish
    return 0.2;
  }

  static List<Map<String, dynamic>> suggest(
    List<Map<String, dynamic>> items, {
    String occasion = 'casual',
    double tempC = 26,
    int count = 3,
  }) {
    final target = _occasionFormality[occasion] ?? 0.35;
    final tops = items.where((e) => e['category'] == 'top').toList();
    final bottoms = items.where((e) => e['category'] == 'bottom').toList();
    final shoes = items.where((e) => e['category'] == 'shoes').toList();
    final outers = items.where((e) => e['category'] == 'outerwear').toList();
    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) return [];

    // Seed changes daily so "surprise me" picks vary day to day.
    final now = DateTime.now();
    final rng = Random(now.year * 10000 + now.month * 100 + now.day);

    final results = <Map<String, dynamic>>[];
    for (final t in tops) {
      for (final b in bottoms) {
        for (final s in shoes) {
          final combo = [t, b, s];
          var score = 3.0;

          // Color harmony across every pair of pieces.
          for (var i = 0; i < combo.length; i++) {
            for (var j = i + 1; j < combo.length; j++) {
              final h1 = (List<int>.from(combo[i]['hues'] as List? ?? [0])).first;
              final h2 = (List<int>.from(combo[j]['hues'] as List? ?? [0])).first;
              score += _pairScore(h1, h2);
            }
          }
          // Formality fit for the occasion.
          for (final e in combo) {
            final f = (e['formality'] as num?)?.toDouble() ?? 0.5;
            score += (1 - (f - target).abs()) * 2;
          }
          // Weather: suggest a layer when it's cold.
          if (tempC < 16 && outers.isNotEmpty) {
            combo.add(outers[rng.nextInt(outers.length)]);
            score += 1.0;
          }
          // Prefer less-worn pieces + honor past feedback.
          for (final e in combo) {
            final w = (e['wearCount'] as num?)?.toInt() ?? 0;
            score += 1 / (1 + w);
            if (e['liked'] == false) score -= 1.5;
            if (e['liked'] == true) score += 0.5;
          }
          results.add({'items': combo, 'score': score + rng.nextDouble() * 0.3});
        }
      }
    }
    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return results.take(count).toList();
  }

  static String reason(Map<String, dynamic> outfit, String occasion) {
    final n = (outfit['items'] as List).length;
    return '$n pieces, color-harmonized for $occasion'
        '${n > 3 ? ", plus a layer for the weather" : ""}, favoring pieces you haven't worn much lately.';
  }
}
