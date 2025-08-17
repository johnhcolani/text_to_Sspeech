import 'package:flutter/foundation.dart';
import '../model/tts_history_item.dart';
import '../services/database_service.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<TtsHistoryItem> _items = [];

  List<TtsHistoryItem> get items => List.unmodifiable(
    _items..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  Future<void> updateFilePath(String id, String filePath) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final old = _items[idx];
    _items[idx] = TtsHistoryItem(
      id: old.id,
      text: old.text,
      filePath: filePath,
      voiceId: old.voiceId,
      rate: old.rate,
      pitch: old.pitch,
      createdAt: old.createdAt,
    );
    await _save();
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final raw = await _databaseService.getHistoryItems();
      _items
        ..clear()
        ..addAll(
          raw.map(
            (e) => TtsHistoryItem(
              id: e['id'] as String,
              text: e['text'] as String,
              filePath: e['filePath'] as String?,
              voiceId: e['voiceId'] as String,
              rate: e['rate'] as double,
              pitch: e['pitch'] as double,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                e['timestamp'] as int,
              ),
            ),
          ),
        );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history from database: $e');
    }
  }

  Future<void> _save() async {
    try {
      for (final item in _items) {
        await _databaseService.insertHistoryItem({
          'id': item.id,
          'text': item.text,
          'filePath': item.filePath,
          'voiceId': item.voiceId,
          'rate': item.rate,
          'pitch': item.pitch,
          'timestamp': item.createdAt.millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('Error saving history to database: $e');
    }
  }

  Future<void> add(TtsHistoryItem item) async {
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _databaseService.deleteHistoryItem(id);
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _databaseService.clearHistory();
    notifyListeners();
  }
}
