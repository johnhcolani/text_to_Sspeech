import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/tts_history_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tts_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tts_history(
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        filePath TEXT,
        voiceId TEXT NOT NULL,
        rate REAL NOT NULL,
        pitch REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Insert a new history item
  Future<void> insertHistoryItem(TtsHistoryItem item) async {
    final db = await database;
    await db.insert(
      'tts_history',
      {
        'id': item.id,
        'text': item.text,
        'filePath': item.filePath,
        'voiceId': item.voiceId,
        'rate': item.rate,
        'pitch': item.pitch,
        'createdAt': item.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all history items
  Future<List<TtsHistoryItem>> getAllHistoryItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tts_history',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return TtsHistoryItem(
        id: maps[i]['id'],
        text: maps[i]['text'],
        filePath: maps[i]['filePath'],
        voiceId: maps[i]['voiceId'],
        rate: maps[i]['rate']?.toDouble() ?? 1.0,
        pitch: maps[i]['pitch']?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  // Delete a history item
  Future<void> deleteHistoryItem(String id) async {
    final db = await database;
    await db.delete(
      'tts_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all history
  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('tts_history');
  }

  // Search history items
  Future<List<TtsHistoryItem>> searchHistoryItems(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tts_history',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return TtsHistoryItem(
        id: maps[i]['id'],
        text: maps[i]['text'],
        filePath: maps[i]['filePath'],
        voiceId: maps[i]['voiceId'],
        rate: maps[i]['rate']?.toDouble() ?? 1.0,
        pitch: maps[i]['pitch']?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    final totalItems = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tts_history')
    ) ?? 0;
    
    return {
      'totalItems': totalItems,
    };
  }
}
