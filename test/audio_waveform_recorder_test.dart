import 'package:flutter_test/flutter_test.dart';
import 'package:audio_waveform_recorder/audio_waveform_recorder.dart';

void main() {
  // ── WaveformData ─────────────────────────────────────────────────────────
  group('WaveformData', () {
    test('empty returns correct defaults', () {
      final w = WaveformData.empty();
      expect(w.isEmpty, isTrue);
      expect(w.samples, isEmpty);
      expect(w.duration, Duration.zero);
    });

    test('withSample appends and clamps', () {
      final w = WaveformData.empty()
          .withSample(0.5)
          .withSample(1.5) // should clamp to 1.0
          .withSample(-0.1); // should clamp to 0.0
      expect(w.samples.length, 3);
      expect(w.samples[0], 0.5);
      expect(w.samples[1], 1.0);
      expect(w.samples[2], 0.0);
    });

    test('resample returns correct count', () {
      final w = WaveformData(
        samples: List.generate(100, (i) => i / 100.0),
        duration: const Duration(seconds: 1),
      );
      final resampled = w.resample(20);
      expect(resampled.length, 20);
    });

    test('resample pads with zeros when fewer samples than count', () {
      const w = WaveformData(
        samples: [0.1, 0.2, 0.3],
        duration: Duration(milliseconds: 100),
      );
      final resampled = w.resample(10);
      expect(resampled.length, 10);
      // Last 7 should be 0.0
      expect(resampled.sublist(3), everyElement(0.0));
    });

    test('peak returns max amplitude', () {
      const w = WaveformData(
        samples: [0.1, 0.9, 0.4, 0.6],
        duration: Duration(seconds: 1),
      );
      expect(w.peak, closeTo(0.9, 0.001));
    });

    test('rms computes correct root mean square', () {
      // All 1.0 → RMS = 1.0
      const full = WaveformData(
        samples: [1.0, 1.0, 1.0],
        duration: Duration(seconds: 1),
      );
      expect(full.rms, closeTo(1.0, 0.001));

      // All 0.0 → RMS = 0.0
      const empty = WaveformData(
        samples: [0.0, 0.0, 0.0],
        duration: Duration(seconds: 1),
      );
      expect(empty.rms, closeTo(0.0, 0.001));
    });

    test('toBytes and fromBytes round-trip', () {
      const original = WaveformData(
        samples: [0.1, 0.5, 0.9, 0.3, 0.7],
        duration: Duration(seconds: 5),
      );
      final bytes = original.toBytes();
      final restored = WaveformData.fromBytes(bytes, original.duration);
      expect(restored.samples.length, original.samples.length);
      for (int i = 0; i < original.samples.length; i++) {
        expect(restored.samples[i], closeTo(original.samples[i], 0.001));
      }
    });
  });

  // ── DurationFormatter ────────────────────────────────────────────────────
  group('DurationFormatter', () {
    test('formats seconds under a minute', () {
      expect(DurationFormatter.format(const Duration(seconds: 34)), '00:34');
    });

    test('formats minutes and seconds', () {
      expect(DurationFormatter.format(const Duration(minutes: 3, seconds: 7)),
          '03:07');
    });

    test('formats hours when >= 1 hour', () {
      expect(
        DurationFormatter.format(
            const Duration(hours: 1, minutes: 5, seconds: 9)),
        '1:05:09',
      );
    });

    test('formatBytes human readable', () {
      expect(DurationFormatter.formatBytes(512), '512 B');
      expect(DurationFormatter.formatBytes(2048), '2.0 KB');
      expect(DurationFormatter.formatBytes(1048576), '1.00 MB');
    });
  });

  // ── RecorderConfig ───────────────────────────────────────────────────────
  group('RecorderConfig', () {
    test('default config has expected values', () {
      const cfg = RecorderConfig();
      expect(cfg.format, AudioFormat.m4a);
      expect(cfg.channels, 1);
      expect(cfg.waveformSampleRate, 100);
      expect(cfg.silenceThreshold, 0.02);
    });

    test('copyWith overrides only specified fields', () {
      const original = RecorderConfig();
      final copy = original.copyWith(channels: 2, format: AudioFormat.wav);
      expect(copy.channels, 2);
      expect(copy.format, AudioFormat.wav);
      expect(copy.bitRate, original.bitRate); // unchanged
    });
  });

  // ── AudioFormat extension ────────────────────────────────────────────────
  group('AudioFormat', () {
    test('extension returns correct file extensions', () {
      expect(AudioFormat.m4a.extension, 'm4a');
      expect(AudioFormat.wav.extension, 'wav');
      expect(AudioFormat.mp4.extension, 'mp4');
      expect(AudioFormat.ogg.extension, 'ogg');
    });

    test('mimeType returns correct MIME strings', () {
      expect(AudioFormat.m4a.mimeType, 'audio/m4a');
      expect(AudioFormat.wav.mimeType, 'audio/wav');
    });
  });

  // ── PlayerController ─────────────────────────────────────────────────────
  group('PlayerController', () {
    test('initial state is idle', () {
      final player = PlayerController();
      expect(player.state, PlaybackState.idle);
      expect(player.isIdle, isTrue);
      expect(player.progress, 0.0);
      player.dispose();
    });

    test('progress is 0 when duration is zero', () {
      final player = PlayerController();
      expect(player.progress, 0.0);
      player.dispose();
    });
  });

  // ── RecorderController ───────────────────────────────────────────────────
  group('RecorderController', () {
    test('initial state is idle', () {
      final ctrl = RecorderController();
      expect(ctrl.isIdle, isTrue);
      expect(ctrl.elapsed, Duration.zero);
      expect(ctrl.waveform.isEmpty, isTrue);
      ctrl.dispose();
    });

    test('reset clears waveform and elapsed', () {
      final ctrl = RecorderController();
      ctrl.reset();
      expect(ctrl.isIdle, isTrue);
      expect(ctrl.waveform.isEmpty, isTrue);
      ctrl.dispose();
    });
  });
}
