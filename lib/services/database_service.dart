import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'tts_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _settingsTable = 'settings';
  static const String _historyTable = 'history';
  static const String _favoritesTable = 'favorites';

  // Settings table columns
  static const String _settingsKey = 'key';
  static const String _settingsValue = 'value';

  // History table columns
  static const String _historyId = 'id';
  static const String _historyText = 'text';
  static const String _historyVoiceId = 'voice_id';
  static const String _historyRate = 'rate';
  static const String _historyPitch = 'pitch';
  static const String _historyFilePath = 'file_path';
  static const String _historyTimestamp = 'timestamp';

  // Favorites table columns
  static const String _favoritesId = 'id';
  static const String _favoritesText = 'text';
  static const String _favoritesVoiceId = 'voice_id';
  static const String _favoritesRate = 'rate';
  static const String _favoritesPitch = 'pitch';
  static const String _favoritesTimestamp = 'timestamp';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create settings table
    await db.execute('''
      CREATE TABLE $_settingsTable (
        $_settingsKey TEXT PRIMARY KEY,
        $_settingsValue TEXT
      )
    ''');

    // Create history table
    await db.execute('''
      CREATE TABLE $_historyTable (
        $_historyId TEXT PRIMARY KEY,
        $_historyText TEXT NOT NULL,
        $_historyVoiceId TEXT NOT NULL,
        $_historyRate REAL NOT NULL,
        $_historyPitch REAL NOT NULL,
        $_historyFilePath TEXT,
        $_historyTimestamp INTEGER NOT NULL
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE $_favoritesTable (
        $_favoritesId TEXT PRIMARY KEY,
        $_favoritesText TEXT NOT NULL,
        $_favoritesVoiceId TEXT NOT NULL,
        $_favoritesRate REAL NOT NULL,
        $_favoritesPitch REAL NOT NULL,
        $_favoritesTimestamp INTEGER NOT NULL
      )
    ''');

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for future versions
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final defaultSettings = [
      {'key': 'selectedLanguage', 'value': 'en-US'},
      {'key': 'selectedVoice', 'value': ''},
      {'key': 'rate', 'value': '0.5'},
      {'key': 'pitch', 'value': '1.0'},
      {'key': 'volume', 'value': '1.0'},
      {'key': 'timingOffset', 'value': '0.8'},
    ];

    for (final setting in defaultSettings) {
      await db.insert(
        _settingsTable,
        setting,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Settings methods
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      _settingsTable,
      where: '$_settingsKey = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      return result.first[_settingsValue] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(_settingsTable, {
      _settingsKey: key,
      _settingsValue: value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeSetting(String key) async {
    final db = await database;
    await db.delete(
      _settingsTable,
      where: '$_settingsKey = ?',
      whereArgs: [key],
    );
  }

  // History methods
  Future<void> insertHistoryItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(_historyTable, {
      _historyId: item['id'],
      _historyText: item['text'],
      _historyVoiceId: item['voiceId'],
      _historyRate: item['rate'],
      _historyPitch: item['pitch'],
      _historyFilePath: item['filePath'],
      _historyTimestamp: item['timestamp'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getHistoryItems() async {
    final db = await database;
    final result = await db.query(
      _historyTable,
      orderBy: '$_historyTimestamp DESC',
    );

    return result
        .map(
          (row) => {
            'id': row[_historyId],
            'text': row[_historyText],
            'voiceId': row[_historyVoiceId],
            'rate': row[_historyRate],
            'pitch': row[_historyPitch],
            'filePath': row[_historyFilePath],
            'timestamp': row[_historyTimestamp],
          },
        )
        .toList();
  }

  Future<void> deleteHistoryItem(String id) async {
    final db = await database;
    await db.delete(_historyTable, where: '$_historyId = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete(_historyTable);
  }

  // Favorites methods
  Future<void> insertFavoriteItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(_favoritesTable, {
      _favoritesId: item['id'],
      _favoritesText: item['text'],
      _favoritesVoiceId: item['voiceId'],
      _favoritesRate: item['rate'],
      _favoritesPitch: item['pitch'],
      _favoritesTimestamp: item['timestamp'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getFavoriteItems() async {
    final db = await database;
    final result = await db.query(
      _favoritesTable,
      orderBy: '$_favoritesTimestamp DESC',
    );

    return result
        .map(
          (row) => {
            'id': row[_favoritesId],
            'text': row[_favoritesText],
            'voiceId': row[_favoritesVoiceId],
            'rate': row[_favoritesRate],
            'pitch': row[_favoritesPitch],
            'timestamp': row[_favoritesTimestamp],
          },
        )
        .toList();
  }

  Future<void> deleteFavoriteItem(String id) async {
    final db = await database;
    await db.delete(
      _favoritesTable,
      where: '$_favoritesId = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearFavorites() async {
    final db = await database;
    await db.delete(_favoritesTable);
  }

  // Utility methods
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    await close();
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
  }
}
