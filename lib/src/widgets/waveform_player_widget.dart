import 'package:flutter/material.dart';
import '../core/player_controller.dart';
import '../core/recorder_config.dart';
import '../core/waveform_data.dart';
import '../painters/waveform_painter.dart';
import '../utils/duration_formatter.dart';
import 'waveform_painter_widget.dart';

/// A complete audio playback widget with waveform scrubbing.
///
/// ```dart
/// WaveformPlayerWidget(
///   filePath: result.filePath,
///   waveform: result.waveform,
///   config: RecorderConfig(playedColor: Colors.blue),
/// )
/// ```
class WaveformPlayerWidget extends StatefulWidget {
  final String filePath;
  final WaveformData? waveform;
  final RecorderConfig config;
  final WaveformStyle style;
  final double waveformHeight;
  final bool showControls;
  final bool showTimer;
  final bool showSpeedControl;
  final void Function(PlaybackState)? onStateChanged;
  final void Function(Duration)? onPositionChanged;

  const WaveformPlayerWidget({
    super.key,
    required this.filePath,
    this.waveform,
    this.config = const RecorderConfig(),
    this.style = WaveformStyle.bars,
    this.waveformHeight = 80.0,
    this.showControls = true,
    this.showTimer = true,
    this.showSpeedControl = true,
    this.onStateChanged,
    this.onPositionChanged,
  });

  @override
  State<WaveformPlayerWidget> createState() => _WaveformPlayerWidgetState();
}

class _WaveformPlayerWidgetState extends State<WaveformPlayerWidget> {
  late PlayerController _player;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = PlayerController();
    _player.addListener(_onPlayerChanged);
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.load(widget.filePath, waveform: widget.waveform);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  void _onPlayerChanged() {
    if (mounted) {
      setState(() {});
      widget.onStateChanged?.call(_player.state);
      widget.onPositionChanged?.call(_player.position);
    }
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: widget.waveformHeight + 80,
        decoration: BoxDecoration(
          color: widget.config.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.config.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform with scrubbing
          WaveformPainterWidget(
            waveform: _player.waveform,
            config: widget.config,
            playbackProgress: _player.progress,
            isPlaying: _player.isPlaying,
            style: widget.style,
            height: widget.waveformHeight,
            onTap: (fraction) => _player.seekToFraction(fraction),
            onDragUpdate: (fraction) => _player.seekToFraction(fraction),
          ),
          const SizedBox(height: 10),

          // Time labels
          if (widget.showTimer) _buildTimeRow(),
          const SizedBox(height: 12),

          // Controls
          if (widget.showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DurationFormatter.format(_player.position),
          style: TextStyle(
            color: widget.config.playedColor,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          DurationFormatter.format(_player.duration),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip back 5s
        IconButton(
          icon: const Icon(Icons.replay_5, color: Colors.white70),
          onPressed: _player.isLoaded ? _player.skipBackward : null,
          tooltip: 'Back 5s',
        ),

        const SizedBox(width: 8),

        // Play / Pause
        GestureDetector(
          onTap: _player.isLoaded ? _player.togglePlayPause : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.config.playedColor,
              boxShadow: [
                BoxShadow(
                  color: widget.config.playedColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _player.isPlaying
                  ? Icons.pause
                  : _player.isCompleted
                      ? Icons.replay
                      : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Skip forward 5s
        IconButton(
          icon: const Icon(Icons.forward_5, color: Colors.white70),
          onPressed: _player.isLoaded ? _player.skipForward : null,
          tooltip: 'Forward 5s',
        ),

        // Speed selector
        if (widget.showSpeedControl) ...[
          const SizedBox(width: 8),
          _SpeedButton(
            speed: _player.speed,
            color: widget.config.playedColor,
            onChanged: _player.setSpeed,
          ),
        ],
      ],
    );
  }
}

// ── Speed toggle button ────────────────────────────────────────────────────

class _SpeedButton extends StatelessWidget {
  final double speed;
  final Color color;
  final Future<void> Function(double) onChanged;

  const _SpeedButton({
    required this.speed,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = speed == 1.0 ? '1×' : '$speed×';
    return GestureDetector(
      onTap: () => _cycleSpeed(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  void _cycleSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(speed);
    final next = speeds[(idx + 1) % speeds.length];
    onChanged(next);
  }
}
