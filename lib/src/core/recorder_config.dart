import 'package:flutter/material.dart';

/// Output audio format.
enum AudioFormat {
  /// AAC in M4A container. Best quality/size ratio. Default.
  m4a,

  /// Raw WAV. Uncompressed, large files. Universal compatibility.
  wav,

  /// AAC in MPEG-4 container. Compatible with most platforms.
  mp4,

  /// OGG Vorbis. Android only. Not supported on iOS.
  ogg,
}

extension AudioFormatExtension on AudioFormat {
  String get extension => switch (this) {
        AudioFormat.m4a => 'm4a',
        AudioFormat.wav => 'wav',
        AudioFormat.mp4 => 'mp4',
        AudioFormat.ogg => 'ogg',
      };

  String get mimeType => switch (this) {
        AudioFormat.m4a => 'audio/m4a',
        AudioFormat.wav => 'audio/wav',
        AudioFormat.mp4 => 'audio/mp4',
        AudioFormat.ogg => 'audio/ogg',
      };
}

/// Audio sample rate in Hz.
enum SampleRate {
  low8k   (8000),
  medium16k(16000),
  high44k  (44100),
  studio48k(48000);

  final int value;
  const SampleRate(this.value);
}

/// Audio bit rate in bits per second (for compressed formats).
enum BitRate {
  low64k   (64000),
  medium128k(128000),
  high256k  (256000);

  final int value;
  const BitRate(this.value);
}

/// Full configuration for the audio recorder.
class RecorderConfig {
  /// Output audio format. Defaults to M4A.
  final AudioFormat format;

  /// Audio sample rate. Defaults to 44.1 kHz.
  final SampleRate sampleRate;

  /// Bit rate for compressed formats. Defaults to 128 kbps.
  final BitRate bitRate;

  /// Number of audio channels. 1 = mono, 2 = stereo. Defaults to mono.
  final int channels;

  /// How often the waveform amplitude is sampled (per second of audio).
  /// Higher = smoother waveform but more memory. Default: 100.
  final int waveformSampleRate;

  /// Maximum recording duration. Null = unlimited.
  final Duration? maxDuration;

  /// Auto-stop recording when silence exceeds this duration.
  /// Null = never auto-stop.
  final Duration? silenceTimeout;

  /// Amplitude threshold (0.0–1.0) below which audio is considered silence.
  final double silenceThreshold;

  /// Directory to save recordings. Null = system temp directory.
  final String? outputDirectory;

  /// Custom filename (without extension). Null = auto-generated timestamp.
  final String? fileName;

  // ── Waveform visual config ──────────────────────────────────────────────

  /// Waveform bar colour while recording.
  final Color recordingColor;

  /// Waveform bar colour when idle / played-back.
  final Color idleColor;

  /// Waveform bar colour for the played portion during playback.
  final Color playedColor;

  /// Background colour of the waveform area.
  final Color backgroundColor;

  /// Width of each waveform bar (dp). Defaults to 3.
  final double barWidth;

  /// Gap between waveform bars (dp). Defaults to 2.
  final double barGap;

  /// Minimum bar height as fraction of total height. Defaults to 0.05.
  final double minBarHeightFraction;

  /// Border radius of each bar. Defaults to 2.
  final double barBorderRadius;

  const RecorderConfig({
    this.format             = AudioFormat.m4a,
    this.sampleRate         = SampleRate.high44k,
    this.bitRate            = BitRate.medium128k,
    this.channels           = 1,
    this.waveformSampleRate = 100,
    this.maxDuration,
    this.silenceTimeout,
    this.silenceThreshold   = 0.02,
    this.outputDirectory,
    this.fileName,
    this.recordingColor     = const Color(0xFFE53935),
    this.idleColor          = const Color(0xFF90A4AE),
    this.playedColor        = const Color(0xFF1E88E5),
    this.backgroundColor    = const Color(0xFF1A1A2E),
    this.barWidth           = 3.0,
    this.barGap             = 2.0,
    this.minBarHeightFraction = 0.05,
    this.barBorderRadius    = 2.0,
  });

  RecorderConfig copyWith({
    AudioFormat? format,
    SampleRate? sampleRate,
    BitRate? bitRate,
    int? channels,
    int? waveformSampleRate,
    Duration? maxDuration,
    Duration? silenceTimeout,
    double? silenceThreshold,
    String? outputDirectory,
    String? fileName,
    Color? recordingColor,
    Color? idleColor,
    Color? playedColor,
    Color? backgroundColor,
    double? barWidth,
    double? barGap,
    double? minBarHeightFraction,
    double? barBorderRadius,
  }) {
    return RecorderConfig(
      format:               format              ?? this.format,
      sampleRate:           sampleRate          ?? this.sampleRate,
      bitRate:              bitRate             ?? this.bitRate,
      channels:             channels            ?? this.channels,
      waveformSampleRate:   waveformSampleRate  ?? this.waveformSampleRate,
      maxDuration:          maxDuration         ?? this.maxDuration,
      silenceTimeout:       silenceTimeout      ?? this.silenceTimeout,
      silenceThreshold:     silenceThreshold    ?? this.silenceThreshold,
      outputDirectory:      outputDirectory     ?? this.outputDirectory,
      fileName:             fileName            ?? this.fileName,
      recordingColor:       recordingColor      ?? this.recordingColor,
      idleColor:            idleColor           ?? this.idleColor,
      playedColor:          playedColor         ?? this.playedColor,
      backgroundColor:      backgroundColor    ?? this.backgroundColor,
      barWidth:             barWidth            ?? this.barWidth,
      barGap:               barGap              ?? this.barGap,
      minBarHeightFraction: minBarHeightFraction ?? this.minBarHeightFraction,
      barBorderRadius:      barBorderRadius     ?? this.barBorderRadius,
    );
  }
}
