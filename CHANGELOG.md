## 0.1.0

* Initial release
* Real-time waveform recording with animated bar display
* Three waveform styles: bars, mirror, line
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
