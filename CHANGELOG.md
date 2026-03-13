## 0.1.2

- Fixed missing Android native files (`build.gradle`, `AndroidManifest.xml`).
- Fixed missing iOS native file (`audio_waveform_recorder.podspec`).
- Resolved Gradle `NullPointerException` during project evaluation.
- Improved compatibility with modern Android Gradle Plugin (AGP) versions.

## 0.1.1

* Fix: `withOpacity` deprecated warnings resolved by switching to `withValues(alpha:)`
* Fix: Shortened package description in `pubspec.yaml` to fix pub score
* Docs: Completely redesigned `README.md` for a premium look on pub.dev

## 0.1.0

* Initial release
* Real-time waveform recording with animated bar display
* Ten waveform styles: bars, mirror, line, equalizer, radial, wave, dots, neon, stacked, pixel
* Pause / resume recording support
* Waveform playback with tap/drag scrubbing
* Speed control (0.5× – 2.0×)
* Silence auto-stop with configurable timeout and threshold
* Maximum duration limit with progress indicator
* WaveformData serialisation (toBytes / fromBytes)
* Waveform extraction from existing audio files
* Android: MediaRecorder + MediaPlayer + MediaCodec waveform extraction
* iOS: AVAudioRecorder + AVAudioPlayer + AVAudioFile + vDSP waveform extraction
* M4A, WAV, MP4, OGG output formats
* Zero external package dependencies
* Full unit test coverage for WaveformData, DurationFormatter, config, controllers
