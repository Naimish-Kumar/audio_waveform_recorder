# audio_waveform_recorder

[![pub.dev](https://img.shields.io/pub/v/audio_waveform_recorder.svg)](https://pub.dev/packages/audio_waveform_recorder)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://pub.dev/packages/audio_waveform_recorder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Record audio with a **real-time animated waveform** and play it back with **waveform scrubbing** — like WhatsApp or Telegram voice messages.

**Zero heavy dependencies.** Pure Dart UI + native platform channels.

---

## ✨ Features

- 🎙 **Real-time waveform** — animated bars update as you speak
- ▶️ **Waveform playback scrubbing** — tap or drag to seek
- 🎨 **3 waveform styles** — bars, mirror, line (SoundCloud)
- 🔴 **Pulsing record indicator** — animated recording dot
- ⏸ **Pause / resume** recording
- ⏭ **Speed control** — 0.5× to 2.0×
- 📊 **Waveform extraction** — from existing audio files too
- 💾 **M4A / WAV / MP4 / OGG** output formats
- 🔕 **Silence auto-stop** — configurable timeout
- ⏱ **Max duration** limit with indicator
- 🎛 **Full customisation** — colours, bar size, themes

---

## 🚀 Installation

```yaml
dependencies:
  audio_waveform_recorder: ^0.1.0
```

**Android** — add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

**iOS** — add to `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio.</string>
```

---

## 📱 Usage

### Drop-in recorder widget
```dart
WaveformRecorderWidget(
  config: RecorderConfig(
    format: AudioFormat.m4a,
    maxDuration: Duration(minutes: 5),
    recordingColor: Colors.red,
    playedColor: Colors.blue,
  ),
  style: WaveformStyle.bars,
  onRecordingComplete: (RecordingResult result) {
    print('File: ${result.filePath}');
    print('Duration: ${result.duration}');
    print('Size: ${result.fileSizeBytes} bytes');
    print('Samples: ${result.waveform.length}');
  },
)
```

### Drop-in player widget
```dart
WaveformPlayerWidget(
  filePath: result.filePath,
  waveform: result.waveform,   // pass from recording for instant display
  config: RecorderConfig(
    playedColor: Colors.blue,
    idleColor: Colors.grey,
  ),
  showSpeedControl: true,
)
```

### Manual control with RecorderController
```dart
final controller = RecorderController(
  config: RecorderConfig(format: AudioFormat.wav),
);

// Request permission
final granted = await controller.requestPermission();

// Start recording
await controller.start();

// Pause / Resume
await controller.pause();
await controller.resume();

// Stop and get result
final result = await controller.stop();
print(result?.filePath);

// Cancel (deletes file)
await controller.cancel();

// Listen to state changes
controller.addListener(() {
  print(controller.currentAmplitude);   // 0.0 – 1.0
  print(controller.elapsed);            // Duration
  print(controller.waveform.samples);   // List<double>
});
```

### Standalone waveform display
```dart
WaveformPainterWidget(
  waveform: myWaveformData,
  config: RecorderConfig(),
  playbackProgress: 0.4,   // 40% played
  style: WaveformStyle.mirror,
  height: 64,
  onTap: (fraction) => player.seekToFraction(fraction),
)
```

### Extract waveform from existing file
```dart
final samples = await AudioChannel.extractWaveform(
  '/path/to/audio.m4a',
  sampleCount: 200,
);
final waveform = WaveformData(
  samples: samples,
  duration: Duration(seconds: 30),
);
```

---

## ⚙️ Configuration

```dart
RecorderConfig(
  // Recording
  format:              AudioFormat.m4a,       // m4a | wav | mp4 | ogg
  sampleRate:          SampleRate.high44k,    // 8k | 16k | 44.1k | 48k
  bitRate:             BitRate.medium128k,    // 64k | 128k | 256k
  channels:            1,                     // 1=mono, 2=stereo
  maxDuration:         Duration(minutes: 5),  // null = unlimited
  silenceTimeout:      Duration(seconds: 3),  // null = no auto-stop
  silenceThreshold:    0.02,                  // 0.0–1.0

  // Waveform visual
  waveformSampleRate:  100,                   // samples per second
  recordingColor:      Colors.red,
  idleColor:           Colors.grey,
  playedColor:         Colors.blue,
  backgroundColor:     Color(0xFF1A1A2E),
  barWidth:            3.0,
  barGap:              2.0,
  barBorderRadius:     2.0,
  minBarHeightFraction: 0.05,
)
```

---

## 🏗 Architecture

```
WaveformRecorderWidget          WaveformPlayerWidget
       │                               │
RecorderController              PlayerController
       │                               │
  AudioChannel (MethodChannel: "audio_waveform_recorder")
       │                               │
  Android: MediaRecorder          Android: MediaPlayer
           MediaExtractor                   + MediaCodec
  iOS:     AVAudioRecorder        iOS:     AVAudioPlayer
           AVAudioFile                      + AVFoundation
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter   # That's it.
```

---

## 📄 License

MIT License
