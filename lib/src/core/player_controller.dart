import 'dart:async';
import 'package:flutter/foundation.dart';
import 'waveform_data.dart';
import '../platform/audio_channel.dart';

/// Playback state.
enum PlaybackState { idle, playing, paused, completed }

/// Controls audio playback with position tracking for waveform scrubbing.
///
/// Usage:
/// ```dart
/// final player = PlayerController();
/// await player.load('/path/to/recording.m4a', waveform: waveformData);
/// await player.play();
/// player.seekTo(Duration(seconds: 5));
/// await player.stop();
/// player.dispose();
/// ```
class PlayerController extends ChangeNotifier {
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  WaveformData _waveform = WaveformData.empty();
  String? _filePath;
  double _volume = 1.0;
  double _speed = 1.0;
  String? _error;

  Timer? _positionTimer;

  // ── Getters ───────────────────────────────────────────────────────────

  PlaybackState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  WaveformData get waveform => _waveform;
  String? get filePath => _filePath;
  double get volume => _volume;
  double get speed => _speed;
  String? get error => _error;

  bool get isIdle => _state == PlaybackState.idle;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isPaused => _state == PlaybackState.paused;
  bool get isCompleted => _state == PlaybackState.completed;
  bool get isLoaded => _filePath != null;

  /// Progress 0.0–1.0 based on position/duration.
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  /// Index of the currently-playing waveform bar.
  int playedBarCount(int totalBars) {
    return (progress * totalBars).round();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Load an audio file for playback.
  ///
  /// [filePath] — absolute path to the audio file.
  /// [waveform] — optional pre-computed waveform data (from recording).
  Future<void> load(String filePath, {WaveformData? waveform}) async {
    await _stopInternal();
    _error = null;
    _filePath = filePath;
    _position = Duration.zero;

    try {
      final info = await AudioChannel.loadAudio(filePath);
      _duration = Duration(milliseconds: info['durationMs'] as int);

      if (waveform != null && waveform.isNotEmpty) {
        _waveform = waveform;
      } else {
        // Generate waveform from file if not provided
        final samples = await AudioChannel.extractWaveform(filePath);
        _waveform = WaveformData(samples: samples, duration: _duration);
      }

      _state = PlaybackState.idle;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Start or resume playback.
  Future<void> play() async {
    if (!isLoaded) return;
    if (isCompleted) await seekTo(Duration.zero);

    await AudioChannel.playAudio();
    _state = PlaybackState.playing;
    _startPositionTracking();
    notifyListeners();
  }

  /// Pause playback.
  Future<void> pause() async {
    if (!isPlaying) return;
    await AudioChannel.pauseAudio();
    _stopPositionTracking();
    _state = PlaybackState.paused;
    notifyListeners();
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop and reset position to zero.
  Future<void> stop() async {
    await _stopInternal();
    notifyListeners();
  }

  Future<void> _stopInternal() async {
    _stopPositionTracking();
    if (!isIdle) {
      try {
        await AudioChannel.stopAudio();
      } catch (_) {}
    }
    _state = PlaybackState.idle;
    _position = Duration.zero;
  }

  /// Seek to a specific position.
  Future<void> seekTo(Duration position) async {
    if (!isLoaded) return;
    final clamped = Duration(
      milliseconds: position.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await AudioChannel.seekTo(clamped.inMilliseconds);
    _position = clamped;
    notifyListeners();
  }

  /// Seek by tapping a fraction (0.0–1.0) on the waveform.
  Future<void> seekToFraction(double fraction) async {
    final ms = (fraction.clamp(0.0, 1.0) * _duration.inMilliseconds).round();
    await seekTo(Duration(milliseconds: ms));
  }

  /// Set playback volume (0.0–1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await AudioChannel.setVolume(_volume);
    notifyListeners();
  }

  /// Set playback speed (0.5–2.0).
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await AudioChannel.setSpeed(_speed);
    notifyListeners();
  }

  /// Skip forward by [duration] (default 5 seconds).
  Future<void> skipForward(
      [Duration duration = const Duration(seconds: 5)]) async {
    await seekTo(_position + duration);
  }

  /// Skip backward by [duration] (default 5 seconds).
  Future<void> skipBackward(
      [Duration duration = const Duration(seconds: 5)]) async {
    await seekTo(_position - duration);
  }

  // ── Internal ──────────────────────────────────────────────────────────

  void _startPositionTracking() {
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!isPlaying) return;
      try {
        final posMs = await AudioChannel.getPlaybackPosition();
        _position = Duration(milliseconds: posMs);

        // Auto-complete
        if (_position >= _duration) {
          _stopPositionTracking();
          _state = PlaybackState.completed;
          _position = _duration;
        }
        notifyListeners();
      } catch (_) {}
    });
  }

  void _stopPositionTracking() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  void dispose() {
    _stopPositionTracking();
    AudioChannel.stopAudio().catchError((_) {});
    super.dispose();
  }
}
