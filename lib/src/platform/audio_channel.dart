import 'package:flutter/services.dart';

/// Dart-side wrapper for all native audio operations.
/// Communicates with Android (Kotlin) and iOS (Swift) via MethodChannel.
class AudioChannel {
  static const _channel = MethodChannel('audio_waveform_recorder');

  // ── Permissions ───────────────────────────────────────────────────────

  static Future<bool> requestMicrophonePermission() async {
    final granted = await _channel.invokeMethod<bool>('requestMicPermission');
    return granted ?? false;
  }

  static Future<bool> hasMicrophonePermission() async {
    final granted = await _channel.invokeMethod<bool>('hasMicPermission');
    return granted ?? false;
  }

  // ── Recording ─────────────────────────────────────────────────────────

  /// Start recording. Returns the output file path.
  static Future<String> startRecording({
    required String format,
    required int sampleRate,
    required int bitRate,
    required int channels,
    String? outputDir,
    String? fileName,
  }) async {
    final path = await _channel.invokeMethod<String>('startRecording', {
      'format':     format,
      'sampleRate': sampleRate,
      'bitRate':    bitRate,
      'channels':   channels,
      if (outputDir != null) 'outputDir': outputDir,
      if (fileName  != null) 'fileName':  fileName,
    });
    if (path == null) throw const AudioException('startRecording returned null path');
    return path;
  }

  /// Pause the active recording.
  static Future<void> pauseRecording() async {
    await _channel.invokeMethod('pauseRecording');
  }

  /// Resume a paused recording.
  static Future<void> resumeRecording() async {
    await _channel.invokeMethod('resumeRecording');
  }

  /// Stop recording. Returns a map with path, durationMs, sizeBytes.
  static Future<Map<String, dynamic>> stopRecording() async {
    final result = await _channel.invokeMethod<Map>('stopRecording');
    if (result == null) throw const AudioException('stopRecording returned null');
    return Map<String, dynamic>.from(result);
  }

  /// Cancel and delete the current recording.
  static Future<void> cancelRecording() async {
    await _channel.invokeMethod('cancelRecording');
  }

  /// Get current recording amplitude as 0.0–1.0.
  static Future<double> getAmplitude() async {
    final amp = await _channel.invokeMethod<double>('getAmplitude');
    return amp ?? 0.0;
  }

  // ── Playback ──────────────────────────────────────────────────────────

  /// Load an audio file. Returns map with durationMs.
  static Future<Map<String, dynamic>> loadAudio(String path) async {
    final result = await _channel.invokeMethod<Map>('loadAudio', {'path': path});
    if (result == null) throw const AudioException('loadAudio returned null');
    return Map<String, dynamic>.from(result);
  }

  /// Start playback.
  static Future<void> playAudio() async {
    await _channel.invokeMethod('playAudio');
  }

  /// Pause playback.
  static Future<void> pauseAudio() async {
    await _channel.invokeMethod('pauseAudio');
  }

  /// Stop playback.
  static Future<void> stopAudio() async {
    await _channel.invokeMethod('stopAudio');
  }

  /// Seek to position in milliseconds.
  static Future<void> seekTo(int positionMs) async {
    await _channel.invokeMethod('seekTo', {'positionMs': positionMs});
  }

  /// Get current playback position in milliseconds.
  static Future<int> getPlaybackPosition() async {
    final pos = await _channel.invokeMethod<int>('getPlaybackPosition');
    return pos ?? 0;
  }

  /// Set volume (0.0–1.0).
  static Future<void> setVolume(double volume) async {
    await _channel.invokeMethod('setVolume', {'volume': volume});
  }

  /// Set playback speed (0.5–2.0).
  static Future<void> setSpeed(double speed) async {
    await _channel.invokeMethod('setSpeed', {'speed': speed});
  }

  // ── Waveform extraction ───────────────────────────────────────────────

  /// Extract waveform amplitude samples from an audio file.
  /// Returns a list of normalised amplitudes (0.0–1.0).
  static Future<List<double>> extractWaveform(String path,
      {int sampleCount = 200}) async {
    final result = await _channel.invokeMethod<List>(
      'extractWaveform',
      {'path': path, 'sampleCount': sampleCount},
    );
    return result?.map((e) => (e as num).toDouble()).toList() ?? [];
  }
}

/// Exception thrown by AudioChannel operations.
class AudioException implements Exception {
  final String message;
  const AudioException(this.message);

  @override
  String toString() => 'AudioException: $message';
}
