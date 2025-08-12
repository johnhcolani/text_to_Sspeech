import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/tts_history_item.dart';

class HistoryProvider extends ChangeNotifier {
  static const _kKey = 'tts_history_v1';
  final List<TtsHistoryItem> _items = [];

  List<TtsHistoryItem> get items =>
      List.unmodifiable(_items..sort((a,b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_kKey) ?? [];
    _items
      ..clear()
      ..addAll(raw.map(TtsHistoryItem.fromJson));
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kKey, _items.map((e) => e.toJson()).toList());
  }

  Future<void> add(TtsHistoryItem item) async {
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    notifyListeners();
  }
}
