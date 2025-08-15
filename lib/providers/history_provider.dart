import 'package:flutter/foundation.dart';
import '../model/tts_history_item.dart';
import '../services/database_service.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<TtsHistoryItem> _items = [];

  List<TtsHistoryItem> get items =>
      List.unmodifiable(_items..sort((a,b) => b.createdAt.compareTo(a.createdAt)));

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
      final items = await _databaseService.getAllHistoryItems();
      _items.clear();
      _items.addAll(items);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _save() async {
    try {
      // Save to database
      for (final item in _items) {
        await _databaseService.insertHistoryItem(item);
      }
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> add(TtsHistoryItem item) async {
    _items.add(item);
    await _databaseService.insertHistoryItem(item);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _databaseService.deleteHistoryItem(id);
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _databaseService.clearAllHistory();
    notifyListeners();
  }

  // Search functionality
  Future<List<TtsHistoryItem>> search(String query) async {
    if (query.isEmpty) {
      return items;
    }
    try {
      return await _databaseService.searchHistoryItems(query);
    } catch (e) {
      debugPrint('Error searching history: $e');
      return [];
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _databaseService.getStatistics();
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {'totalItems': 0};
    }
  }
}
