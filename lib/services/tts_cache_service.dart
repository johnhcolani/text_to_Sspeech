import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for managing TTS cache and synthesis file operations
///
/// Handles creation, storage, retrieval, and cleanup of cached TTS audio files.
class TTSCacheService {
  static final TTSCacheService _instance = TTSCacheService._internal();
  factory TTSCacheService() => _instance;
  TTSCacheService._internal();

  late Directory _cacheDir;
  bool _initialized = false;

  /// Initialize cache directory
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _cacheDir = await getTemporaryDirectory();
      final ttsCacheDir = Directory(p.join(_cacheDir.path, 'tts_cache'));

      if (!await ttsCacheDir.exists()) {
        await ttsCacheDir.create(recursive: true);
      }

      _cacheDir = ttsCacheDir;
      _initialized = true;
      debugPrint('TTSCacheService initialized at: ${_cacheDir.path}');
    } catch (e) {
      debugPrint('Error initializing TTSCacheService: $e');
      rethrow;
    }
  }

  /// Generates a cache file path for TTS synthesis
  ///
  /// Creates a path based on text content hash and voice settings.
  String getCacheFilePath({
    required String textHash,
    required String voiceId,
    required double rate,
    required double pitch,
  }) {
    final key = '${textHash}_${voiceId}_${rate}_$pitch';
    final fileName = '${_generateHash(key)}.wav';
    return p.join(_cacheDir.path, fileName);
  }

  /// Checks if a cached file exists and is valid
  Future<bool> isCacheValid(String cacheFilePath) async {
    try {
      final file = File(cacheFilePath);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      // File must be at least 1KB to be considered valid
      return stat.size > 1024;
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
  }

  /// Gets the size of a cache file
  Future<int> getCacheFileSize(String cacheFilePath) async {
    try {
      final file = File(cacheFilePath);
      if (!await file.exists()) return 0;
      return (await file.stat()).size;
    } catch (e) {
      debugPrint('Error getting cache file size: $e');
      return 0;
    }
  }

  /// Deletes a specific cache file
  Future<bool> deleteCacheFile(String cacheFilePath) async {
    try {
      final file = File(cacheFilePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted cache file: $cacheFilePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting cache file: $e');
      return false;
    }
  }

  /// Clears all TTS cache files
  Future<int> clearAllCache() async {
    try {
      int deletedCount = 0;
      final files = _cacheDir.listSync(recursive: false);

      for (final file in files) {
        if (file is File && file.path.endsWith('.wav')) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            debugPrint('Error clearing cache file ${file.path}: $e');
          }
        }
      }

      debugPrint('Cleared TTS cache: deleted $deletedCount files');
      return deletedCount;
    } catch (e) {
      debugPrint('Error clearing TTS cache: $e');
      return 0;
    }
  }

  /// Gets total size of all cached files in bytes
  Future<int> getCacheTotalSize() async {
    try {
      int totalSize = 0;
      final files = _cacheDir.listSync(recursive: false);

      for (final file in files) {
        if (file is File) {
          try {
            final stat = await file.stat();
            totalSize += stat.size;
          } catch (e) {
            debugPrint('Error getting file size: $e');
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache total size: $e');
      return 0;
    }
  }

  /// Gets cache directory path
  String get cacheDir => _cacheDir.path;

  /// Generates a simple hash from a string
  static String _generateHash(String input) {
    // Simple hash function for cache key generation
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.abs().toString().padLeft(10, '0');
  }
}
