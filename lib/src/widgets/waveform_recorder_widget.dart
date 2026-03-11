import 'dart:async';
import 'package:flutter/material.dart';
import '../core/recorder_controller.dart';
import '../core/recorder_config.dart';
import '../painters/waveform_painter.dart';
import '../utils/duration_formatter.dart';
import 'waveform_painter_widget.dart';

/// A complete, drop-in audio recording widget with real-time waveform.
///
/// Handles its own [RecorderController] lifecycle unless you provide one.
///
/// ```dart
/// WaveformRecorderWidget(
///   config: RecorderConfig(
///     format: AudioFormat.m4a,
///     recordingColor: Colors.red,
///   ),
///   onRecordingComplete: (result) {
///     print('Saved to: ${result.filePath}');
///   },
/// )
/// ```
class WaveformRecorderWidget extends StatefulWidget {
  /// Optional external controller. If null, an internal one is created.
  final RecorderController? controller;

  /// Configuration for recording and visual appearance.
  final RecorderConfig config;

  /// Waveform visual style.
  final WaveformStyle style;

  /// Height of the waveform display area.
  final double waveformHeight;

  /// Called when recording finishes. Null if user cancelled.
  final void Function(RecordingResult result)? onRecordingComplete;

  /// Called when recording is cancelled.
  final void Function()? onRecordingCancelled;

  /// Called on every amplitude update.
  final void Function(double amplitude)? onAmplitudeChanged;

  /// Show the built-in control buttons (record/pause/stop/cancel).
  final bool showControls;

  /// Show the elapsed time display.
  final bool showTimer;

  /// Show max duration indicator (if config.maxDuration is set).
  final bool showMaxDuration;

  /// Custom record button builder.
  final Widget Function(RecordingState state, VoidCallback onPressed)? recordButtonBuilder;

  const WaveformRecorderWidget({
    super.key,
    this.controller,
    this.config       = const RecorderConfig(),
    this.style        = WaveformStyle.bars,
    this.waveformHeight = 80.0,
    this.onRecordingComplete,
    this.onRecordingCancelled,
    this.onAmplitudeChanged,
    this.showControls   = true,
    this.showTimer      = true,
    this.showMaxDuration = true,
    this.recordButtonBuilder,
  });

  @override
  State<WaveformRecorderWidget> createState() => _WaveformRecorderWidgetState();
}

class _WaveformRecorderWidgetState extends State<WaveformRecorderWidget>
    with SingleTickerProviderStateMixin {
  late RecorderController _controller;
  bool _ownsController = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = RecorderController(config: widget.config);
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
    widget.onAmplitudeChanged?.call(_controller.currentAmplitude);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _handleRecordPress() async {
    if (_controller.isIdle || _controller.isStopped) {
      final hasPermission = await _controller.hasPermission();
      if (!hasPermission) {
        final granted = await _controller.requestPermission();
        if (!granted) {
          _showPermissionDenied();
          return;
        }
      }
      await _controller.start();
    } else if (_controller.isRecording) {
      await _controller.pause();
    } else if (_controller.isPaused) {
      await _controller.resume();
    }
  }

  Future<void> _handleStop() async {
    final result = await _controller.stop();
    if (result != null) {
      widget.onRecordingComplete?.call(result);
    }
  }

  Future<void> _handleCancel() async {
    await _controller.cancel();
    widget.onRecordingCancelled?.call();
  }

  void _showPermissionDenied() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission denied. Please enable it in settings.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error banner
          if (_controller.error != null) _buildError(),

          // Timer row
          if (widget.showTimer) _buildTimer(),
          const SizedBox(height: 12),

          // Waveform
          _buildWaveform(),
          const SizedBox(height: 16),

          // Controls
          if (widget.showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final maxMs = widget.config.maxDuration?.inMilliseconds;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Recording indicator dot
        Row(children: [
          if (_controller.isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.config.recordingColor
                      .withOpacity(_pulseAnim.value),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            DurationFormatter.format(_controller.elapsed),
            style: TextStyle(
              color: _controller.isRecording
                  ? widget.config.recordingColor
                  : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ]),

        // Max duration
        if (widget.showMaxDuration && maxMs != null)
          Text(
            DurationFormatter.format(widget.config.maxDuration!),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildWaveform() {
    return WaveformPainterWidget(
      waveform:         _controller.waveform,
      config:           widget.config,
      isRecording:      _controller.isRecording,
      currentAmplitude: _controller.currentAmplitude,
      style:            widget.style,
      height:           widget.waveformHeight,
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade700, width: 1),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _controller.error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel button (visible when recording or paused)
        AnimatedOpacity(
          opacity: (_controller.isRecording || _controller.isPaused) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _ControlButton(
            icon: Icons.close,
            color: Colors.grey,
            size: 44,
            onPressed: (_controller.isRecording || _controller.isPaused)
                ? _handleCancel
                : null,
            tooltip: 'Cancel',
          ),
        ),
        const SizedBox(width: 20),

        // Main record / pause / resume button
        if (widget.recordButtonBuilder != null)
          widget.recordButtonBuilder!(
            _controller.state,
            _handleRecordPress,
          )
        else
          _buildMainButton(),

        const SizedBox(width: 20),

        // Stop / Done button (visible when recording or paused)
        AnimatedOpacity(
          opacity: (_controller.isRecording || _controller.isPaused) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _ControlButton(
            icon: Icons.stop,
            color: widget.config.playedColor,
            size: 44,
            onPressed: (_controller.isRecording || _controller.isPaused)
                ? _handleStop
                : null,
            tooltip: 'Done',
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    final isActive = _controller.isRecording;
    final isPaused = _controller.isPaused;
    final isStopped = _controller.isStopped;

    IconData icon;
    Color color;
    String tooltip;

    if (isActive) {
      icon    = Icons.pause;
      color   = widget.config.recordingColor;
      tooltip = 'Pause';
    } else if (isPaused) {
      icon    = Icons.mic;
      color   = widget.config.recordingColor;
      tooltip = 'Resume';
    } else if (isStopped) {
      icon    = Icons.refresh;
      color   = widget.config.playedColor;
      tooltip = 'Record again';
    } else {
      icon    = Icons.mic;
      color   = widget.config.recordingColor;
      tooltip = 'Start recording';
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: isActive ? _pulseAnim.value * 0.1 + 0.95 : 1.0,
        child: child,
      ),
      child: _ControlButton(
        icon:      icon,
        color:     color,
        size:      64,
        onPressed: isStopped ? _controller.reset : _handleRecordPress,
        tooltip:   tooltip,
        filled:    true,
      ),
    );
  }
}

// ── Small control button ──────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool filled;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    required this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (onPressed != null ? color : Colors.grey.shade800)
                : Colors.transparent,
            border: filled
                ? null
                : Border.all(
                    color: onPressed != null ? color : Colors.grey.shade700,
                    width: 2,
                  ),
          ),
          child: Icon(
            icon,
            color: filled
                ? Colors.white
                : (onPressed != null ? color : Colors.grey.shade700),
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}
