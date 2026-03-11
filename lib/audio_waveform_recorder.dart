/// Audio Waveform Recorder
/// Record audio with real-time waveform + playback with scrubbing.
/// Zero external dependencies — pure Dart UI + native platform channels.
library;

export 'src/core/recorder_controller.dart';
export 'src/core/player_controller.dart';
export 'src/core/waveform_data.dart';
export 'src/core/recorder_config.dart';
export 'src/painters/waveform_painter.dart';
export 'src/widgets/waveform_recorder_widget.dart';
export 'src/widgets/waveform_player_widget.dart';
export 'src/widgets/waveform_painter_widget.dart';
export 'src/platform/audio_channel.dart';
export 'src/utils/duration_formatter.dart';
