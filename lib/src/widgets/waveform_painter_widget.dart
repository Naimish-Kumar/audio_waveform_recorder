import 'package:flutter/material.dart';
import '../core/waveform_data.dart';
import '../core/recorder_config.dart';
import '../painters/waveform_painter.dart';

/// A standalone widget that renders a [WaveformData] using [CustomPainter].
/// Can be used independently for displaying pre-recorded waveforms.
///
/// ```dart
/// WaveformPainterWidget(
///   waveform: myWaveform,
///   config: RecorderConfig(),
///   playbackProgress: 0.4,
///   style: WaveformStyle.bars,
/// )
/// ```
class WaveformPainterWidget extends StatelessWidget {
  final WaveformData waveform;
  final RecorderConfig config;
  final double playbackProgress;
  final bool isRecording;
  final bool isPlaying;
  final double currentAmplitude;
  final WaveformStyle style;
  final double height;
  final void Function(double fraction)? onTap;
  final void Function(double fraction)? onDragUpdate;

  const WaveformPainterWidget({
    super.key,
    required this.waveform,
    this.config = const RecorderConfig(),
    this.playbackProgress = 0.0,
    this.isRecording = false,
    this.isPlaying = false,
    this.currentAmplitude = 0.0,
    this.style = WaveformStyle.bars,
    this.height = 64.0,
    this.onTap,
    this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Widget painter = CustomPaint(
      size: Size.fromHeight(height),
      painter: WaveformPainter(
        waveform: waveform,
        config: config,
        playbackProgress: playbackProgress,
        isRecording: isRecording,
        isPlaying: isPlaying,
        currentAmplitude: currentAmplitude,
        style: style,
      ),
    );

    if (onTap != null || onDragUpdate != null) {
      painter = GestureDetector(
        onTapDown: (d) => _onGesture(d.localPosition, context),
        onPanUpdate: (d) => _onGesture(d.localPosition, context),
        child: painter,
      );
    }

    return SizedBox(height: height, child: painter);
  }

  void _onGesture(Offset local, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final fraction = (local.dx / box.size.width).clamp(0.0, 1.0);
    onTap?.call(fraction);
    onDragUpdate?.call(fraction);
  }
}
