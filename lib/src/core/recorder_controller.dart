import 'dart:async';
import 'package:flutter/foundation.dart';
import 'recorder_config.dart';
import 'waveform_data.dart';
import '../platform/audio_channel.dart';

/// Recording state machine.
enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}

/// Result returned after recording completes.
class RecordingResult {
  /// Absolute path to the saved audio file.
  final String filePath;

  /// Total duration of the recording.
  final Duration duration;

  /// Waveform amplitude data captured during recording.
  final WaveformData waveform;

  /// File size in bytes.
  final int fileSizeBytes;

  const RecordingResult({
    required this.filePath,
    required this.duration,
    required this.waveform,
    required this.fileSizeBytes,
  });

  @override
  String toString() => 'RecordingResult(path: $filePath, duration: $duration, '
      'samples: ${waveform.length}, size: $fileSizeBytes bytes)';
}

/// Controls audio recording with real-time waveform amplitude streaming.
///
/// Usage:
/// ```dart
/// final controller = RecorderController();
/// await controller.start();
/// // ... user records
/// final result = await controller.stop();
/// print(result.filePath);
/// controller.dispose();
/// ```
class RecorderController extends ChangeNotifier {
  RecorderConfig _config;
  RecordingState _state = RecordingState.idle;
  WaveformData _waveform = WaveformData.empty();
  Duration _elapsed = Duration.zero;
  double _currentAmplitude = 0.0;
  String? _error;

  // Internal
  Timer? _amplitudeTimer;
  Timer? _durationTimer;
  Timer? _silenceTimer;
  final Stopwatch _stopwatch = Stopwatch();

  RecorderController({RecorderConfig config = const RecorderConfig()})
      : _config = config;

  // ── Public getters ────────────────────────────────────────────────────

  RecorderConfig get config => _config;
  RecordingState get state => _state;
  WaveformData get waveform => _waveform;
  Duration get elapsed => _elapsed;
  double get currentAmplitude => _currentAmplitude;
  String? get error => _error;

  bool get isIdle => _state == RecordingState.idle;
  bool get isRecording => _state == RecordingState.recording;
  bool get isPaused => _state == RecordingState.paused;
  bool get isStopped => _state == RecordingState.stopped;

  /// Update config (only when not recording).
  void updateConfig(RecorderConfig config) {
    if (isRecording) return;
    _config = config;
    notifyListeners();
  }

  // ── Recording lifecycle ───────────────────────────────────────────────

  /// Request microphone permission. Returns true if granted.
  Future<bool> requestPermission() async {
    return AudioChannel.requestMicrophonePermission();
  }

  /// Check if microphone permission is already granted.
  Future<bool> hasPermission() async {
    return AudioChannel.hasMicrophonePermission();
  }

  /// Start recording.
  ///
  /// Throws [AudioException] if permission denied or recorder fails to start.
  Future<void> start() async {
    if (isRecording) return;

    _error = null;
    _waveform = WaveformData.empty();
    _elapsed = Duration.zero;
    _currentAmplitude = 0.0;

    try {
      await AudioChannel.startRecording(
        format: _config.format.extension,
        sampleRate: _config.sampleRate.value,
        bitRate: _config.bitRate.value,
        channels: _config.channels,
        outputDir: _config.outputDirectory,
        fileName: _config.fileName,
      );

      _state = RecordingState.recording;
      _stopwatch.reset();
      _stopwatch.start();

      _startAmplitudePolling();
      _startDurationTimer();

      if (_config.maxDuration != null) {
        Future.delayed(_config.maxDuration!, stop);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = RecordingState.idle;
      notifyListeners();
      rethrow;
    }
  }

  /// Pause an active recording.
  Future<void> pause() async {
    if (!isRecording) return;
    await AudioChannel.pauseRecording();
    _stopwatch.stop();
    _stopAmplitudePolling();
    _state = RecordingState.paused;
    notifyListeners();
  }

  /// Resume a paused recording.
  Future<void> resume() async {
    if (!isPaused) return;
    await AudioChannel.resumeRecording();
    _stopwatch.start();
    _startAmplitudePolling();
    _state = RecordingState.recording;
    notifyListeners();
  }

  /// Stop recording and return the result.
  Future<RecordingResult?> stop() async {
    if (isIdle) return null;

    _stopAmplitudePolling();
    _stopDurationTimer();
    _stopwatch.stop();

    try {
      final result = await AudioChannel.stopRecording();
      _state = RecordingState.stopped;

      final recording = RecordingResult(
        filePath: result['path'] as String,
        duration: Duration(milliseconds: result['durationMs'] as int),
        waveform: _waveform.withDuration(_elapsed),
        fileSizeBytes: result['sizeBytes'] as int,
      );

      notifyListeners();
      return recording;
    } catch (e) {
      _error = e.toString();
      _state = RecordingState.stopped;
      notifyListeners();
      rethrow;
    }
  }

  /// Discard the current recording without saving.
  Future<void> cancel() async {
    _stopAmplitudePolling();
    _stopDurationTimer();
    _stopwatch.stop();
    await AudioChannel.cancelRecording();
    _state = RecordingState.idle;
    _waveform = WaveformData.empty();
    _elapsed = Duration.zero;
    _currentAmplitude = 0.0;
    notifyListeners();
  }

  /// Reset to idle state (after stopped).
  void reset() {
    _state = RecordingState.idle;
    _waveform = WaveformData.empty();
    _elapsed = Duration.zero;
    _currentAmplitude = 0.0;
    _error = null;
    notifyListeners();
  }

  // ── Internal timers ───────────────────────────────────────────────────

  void _startAmplitudePolling() {
    final interval = Duration(
      milliseconds: (1000 / _config.waveformSampleRate).round(),
    );
    _amplitudeTimer = Timer.periodic(interval, (_) async {
      if (!isRecording) return;
      try {
        final amp = await AudioChannel.getAmplitude();
        _currentAmplitude = amp.clamp(0.0, 1.0);
        _waveform = _waveform.withSample(_currentAmplitude);

        // Silence detection
        if (_config.silenceTimeout != null) {
          if (_currentAmplitude < _config.silenceThreshold) {
            _silenceTimer ??= Timer(_config.silenceTimeout!, stop);
          } else {
            _silenceTimer?.cancel();
            _silenceTimer = null;
          }
        }

        notifyListeners();
      } catch (_) {}
    });
  }

  void _stopAmplitudePolling() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isRecording) return;
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  void dispose() {
    _stopAmplitudePolling();
    _stopDurationTimer();
    super.dispose();
  }
}
