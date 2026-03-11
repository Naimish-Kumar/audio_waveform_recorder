import 'dart:math';
import 'dart:typed_data';

/// Stores a list of normalised amplitude samples (0.0 – 1.0)
/// captured during recording or decoded from an audio file.
class WaveformData {
  /// Raw amplitude samples, each in range [0.0, 1.0].
  final List<double> samples;

  /// Total audio duration this waveform represents.
  final Duration duration;

  /// Sample rate used when capturing (samples per second of audio).
  final int sampleRate;

  const WaveformData({
    required this.samples,
    required this.duration,
    this.sampleRate = 100,
  });

  /// Empty waveform with no data.
  factory WaveformData.empty() => const WaveformData(
        samples: [],
        duration: Duration.zero,
      );

  bool get isEmpty => samples.isEmpty;
  bool get isNotEmpty => samples.isNotEmpty;
  int get length => samples.length;

  /// Get a subsample of [count] evenly-spaced points from the full data.
  /// Used by the painter to fit waveform into available pixel width.
  List<double> resample(int count) {
    if (samples.isEmpty || count <= 0) return List.filled(count, 0.0);
    if (samples.length <= count) {
      // Pad with zeros if fewer samples than needed
      return [...samples, ...List.filled(count - samples.length, 0.0)];
    }
    final result = <double>[];
    final step = samples.length / count;
    for (int i = 0; i < count; i++) {
      final start = (i * step).floor();
      final end = min(((i + 1) * step).ceil(), samples.length);
      // Average the bucket
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += samples[j];
      }
      result.add(sum / (end - start));
    }
    return result;
  }

  /// Peak amplitude (0.0 – 1.0).
  double get peak => samples.isEmpty ? 0.0 : samples.reduce(max);

  /// RMS (Root Mean Square) amplitude — perceived loudness.
  double get rms {
    if (samples.isEmpty) return 0.0;
    final sumSq = samples.fold<double>(0, (s, v) => s + v * v);
    return sqrt(sumSq / samples.length);
  }

  /// Return a copy with a new sample appended.
  WaveformData withSample(double amplitude) {
    return WaveformData(
      samples: [...samples, amplitude.clamp(0.0, 1.0)],
      duration: duration,
      sampleRate: sampleRate,
    );
  }

  /// Return a copy with updated duration.
  WaveformData withDuration(Duration d) {
    return WaveformData(samples: samples, duration: d, sampleRate: sampleRate);
  }

  /// Serialise to a simple Float32 byte buffer for storage / transfer.
  Uint8List toBytes() {
    final buf = Float32List.fromList(samples.map((s) => s.toDouble()).toList());
    return buf.buffer.asUint8List();
  }

  /// Deserialise from bytes produced by [toBytes].
  factory WaveformData.fromBytes(Uint8List bytes, Duration duration) {
    final floats = Float32List.view(bytes.buffer);
    return WaveformData(
      samples: floats.toList(),
      duration: duration,
    );
  }

  @override
  String toString() =>
      'WaveformData(samples: ${samples.length}, duration: $duration, peak: ${peak.toStringAsFixed(3)})';
}
