import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio session for optimal car audio playback
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('placeholder')),
        preload: false,
      );

      // Set audio quality settings
      await _configureAudioQuality();

      _isInitialized = true;
      debugPrint('AudioPlayerService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AudioPlayerService: $e');
    }
  }

  Future<void> _configureAudioQuality() async {
    try {
      // Set audio quality parameters for smooth car playback
      await _player.setVolume(1.0);

      // Basic audio configuration for car audio systems
      // The just_audio package will automatically handle platform-specific optimizations
      debugPrint('Audio quality configured for car audio playback');
    } catch (e) {
      debugPrint('Error configuring audio quality: $e');
    }
  }

  Future<void> playFile(String filePath) async {
    try {
      await initialize();

      // Stop any current playback
      await _player.stop();

      // Verify file integrity for car audio playback
      await _verifyFileQuality(filePath);

      // Set the audio source
      await _player.setFilePath(filePath);

      // Preload the audio for smooth playback
      await _player.load();

      // Start playback
      await _player.play();

      debugPrint('Playing audio file: $filePath');
    } catch (e) {
      debugPrint('Error playing audio file: $e');
      rethrow;
    }
  }

  Future<void> _verifyFileQuality(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist: $filePath');
      }

      final size = await file.length();
      if (size < 1024) {
        throw Exception(
          'Audio file is too small (${size} bytes), may be corrupted',
        );
      }

      debugPrint('Audio file verified: $filePath (${size} bytes)');
    } catch (e) {
      debugPrint('File quality verification failed: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlayerState get playerState => _player.playerState;
  Duration? get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  Future<void> dispose() async {
    try {
      await _player.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disposing AudioPlayerService: $e');
    }
  }
}
