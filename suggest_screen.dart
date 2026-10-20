import 'dart:io';
import 'package:flutter/material.dart';
import '../services/stylist_engine.dart';
import '../services/wardrobe_db.dart';

class SuggestScreen extends StatefulWidget {
  const SuggestScreen({super.key});
  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  String _occasion = 'casual';
  double _temp = 26;
  List<Map<String, dynamic>> _suggestions = [];

  static const _occasions = ['gym', 'casual', 'date', 'party', 'office'];

  Future<void> _generate() async {
    final picks = StylistEngine.suggest(
      WardrobeDb.items(), occasion: _occasion, tempC: _temp, count: 3);
    setState(() => _suggestions = picks);
  }

  Future<void> _markWorn(Map<String, dynamic> outfit) async {
    for (final e in outfit['items'] as List) {
      final id = e['id'] as String;
      final cur = (e['wearCount'] as num?)?.toInt() ?? 0;
      await WardrobeDb.update(id, {'wearCount': cur + 1});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as worn — future picks will favor fresh combos.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Style me')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(spacing: 8, children: [
              for (final o in _occasions)
                ChoiceChip(label: Text(o), selected: _occasion == o,
                  onSelected: (_) => setState(() => _occasion = o)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('Cold'),
              Expanded(child: Slider(value: _temp, min: -5, max: 45, divisions: 50,
                label: '${_temp.round()}°C', onChanged: (v) => setState(() => _temp = v))),
              const Text('Hot'),
            ]),
          ),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Suggest outfits'),
          ),
          Expanded(
            child: _suggestions.isEmpty
                ? const Center(child: Text('Pick an occasion and generate.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) {
                      final o = _suggestions[i];
                      final items = o['items'] as List;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text('Option ${i + 1}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _markWorn(o),
                                icon: const Icon(Icons.check),
                                label: const Text('Worn it')),
                            ]),
                            SizedBox(
                              height: 110,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, j) {
                                  final it = items[j];
                                  return Column(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(File(it['imagePath'] as String),
                                          width: 80, height: 80, fit: BoxFit.cover),
                                    ),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      GestureDetector(
                                        onTap: () => WardrobeDb.update(
                                            it['id'] as String, {'liked': true}),
                                        child: const Icon(Icons.thumb_up_outlined, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => WardrobeDb.update(
                                            it['id'] as String, {'liked': false}),
                                        child: const Icon(Icons.thumb_down_outlined, size: 16),
                                      ),
                                    ]),
                                  ]);
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(StylistEngine.reason(o, _occasion),
                                style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      );
}
