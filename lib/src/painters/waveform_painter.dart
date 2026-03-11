import 'dart:math';
import 'package:flutter/material.dart';
import '../core/waveform_data.dart';
import '../core/recorder_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WaveformStyle — 10 styles
// ─────────────────────────────────────────────────────────────────────────────

/// All available waveform visual styles.
enum WaveformStyle {
  /// ① Classic centre-aligned bars — WhatsApp / Telegram style.
  bars,

  /// ② Symmetrical mirror bars, top + bottom — Spotify style.
  mirror,

  /// ③ Filled closed-path shape — SoundCloud style.
  line,

  /// ④ Bottom-anchored histogram bars — equaliser / DJ style.
  equalizer,

  /// ⑤ Circular radial bars emanating from centre — vinyl / radar style.
  radial,

  /// ⑥ Smooth cubic-bezier filled wave with gradient — Apple Music style.
  wave,

  /// ⑦ Dot matrix — amplitude mapped to dot radius — retro LED style.
  dots,

  /// ⑧ Glowing neon bars with bloom shadow — cyberpunk style.
  neon,

  /// ⑨ Stacked semi-transparent layers with depth — holographic style.
  stacked,

  /// ⑩ Pixel-art blocky cells on a grid — retro game style.
  pixel,
}

// ─────────────────────────────────────────────────────────────────────────────
//  WaveformStyleConfig — per-style extra knobs
// ─────────────────────────────────────────────────────────────────────────────

/// Extra per-style configuration that goes beyond [RecorderConfig].
class WaveformStyleConfig {
  // ── Gradient ──────────────────────────────────────────────────────────────
  /// Enable gradient fill instead of a flat colour.
  final bool useGradient;

  /// Gradient colours for played/recording region (top → bottom).
  final List<Color> gradientColors;

  /// Gradient colours for idle/unplayed region.
  final List<Color> idleGradientColors;

  // ── Glow / neon ───────────────────────────────────────────────────────────
  /// Blur radius for neon glow. Set to 0 to disable.
  final double glowRadius;

  /// Number of glow layers (more = softer but heavier). Default 2.
  final int glowLayers;

  // ── Radial ────────────────────────────────────────────────────────────────
  /// Inner radius as fraction of the smaller dimension (radial style).
  final double radialInnerFraction;

  /// Whether radial bars have rounded tips.
  final bool radialRoundedTips;

  // ── Wave ──────────────────────────────────────────────────────────────────
  /// Number of stacked transparent layers (wave + stacked styles).
  final int waveLayerCount;

  /// Vertical offset between stacked layers (fraction of height).
  final double waveLayerOffset;

  // ── Dots ──────────────────────────────────────────────────────────────────
  /// Number of dot rows in the dot-matrix style.
  final int dotRows;

  /// Whether dots are filled or stroked rings.
  final bool dotFilled;

  // ── Pixel ─────────────────────────────────────────────────────────────────
  /// Number of pixel rows in the pixel / retro style.
  final int pixelRows;

  /// Gap between pixel cells (dp).
  final double pixelGap;

  // ── Equalizer ─────────────────────────────────────────────────────────────
  /// Show peak indicator dots above equalizer bars.
  final bool equalizerShowPeak;

  /// How quickly peak dots fall back down (0 = instant, 1 = never).
  final double equalizerPeakDecay;

  // ── Playhead ─────────────────────────────────────────────────────────────
  /// Show playhead cursor line.
  final bool showPlayhead;

  /// Playhead style.
  final PlayheadStyle playheadStyle;

  // ── Mirror ────────────────────────────────────────────────────────────────
  /// Opacity of the bottom mirror reflection.
  final double mirrorReflectionOpacity;

  const WaveformStyleConfig({
    this.useGradient             = false,
    this.gradientColors          = const [Color(0xFFE53935), Color(0xFFFF7043)],
    this.idleGradientColors      = const [Color(0xFF607D8B), Color(0xFF455A64)],
    this.glowRadius              = 8.0,
    this.glowLayers              = 2,
    this.radialInnerFraction     = 0.25,
    this.radialRoundedTips       = true,
    this.waveLayerCount          = 3,
    this.waveLayerOffset         = 0.08,
    this.dotRows                 = 8,
    this.dotFilled               = true,
    this.pixelRows               = 10,
    this.pixelGap                = 1.5,
    this.equalizerShowPeak       = true,
    this.equalizerPeakDecay      = 0.92,
    this.showPlayhead            = true,
    this.playheadStyle           = PlayheadStyle.line,
    this.mirrorReflectionOpacity = 0.45,
  });

  WaveformStyleConfig copyWith({
    bool? useGradient,
    List<Color>? gradientColors,
    List<Color>? idleGradientColors,
    double? glowRadius,
    int? glowLayers,
    double? radialInnerFraction,
    bool? radialRoundedTips,
    int? waveLayerCount,
    double? waveLayerOffset,
    int? dotRows,
    bool? dotFilled,
    int? pixelRows,
    double? pixelGap,
    bool? equalizerShowPeak,
    double? equalizerPeakDecay,
    bool? showPlayhead,
    PlayheadStyle? playheadStyle,
    double? mirrorReflectionOpacity,
  }) =>
      WaveformStyleConfig(
        useGradient:             useGradient             ?? this.useGradient,
        gradientColors:          gradientColors          ?? this.gradientColors,
        idleGradientColors:      idleGradientColors      ?? this.idleGradientColors,
        glowRadius:              glowRadius              ?? this.glowRadius,
        glowLayers:              glowLayers              ?? this.glowLayers,
        radialInnerFraction:     radialInnerFraction     ?? this.radialInnerFraction,
        radialRoundedTips:       radialRoundedTips       ?? this.radialRoundedTips,
        waveLayerCount:          waveLayerCount          ?? this.waveLayerCount,
        waveLayerOffset:         waveLayerOffset         ?? this.waveLayerOffset,
        dotRows:                 dotRows                 ?? this.dotRows,
        dotFilled:               dotFilled               ?? this.dotFilled,
        pixelRows:               pixelRows               ?? this.pixelRows,
        pixelGap:                pixelGap                ?? this.pixelGap,
        equalizerShowPeak:       equalizerShowPeak       ?? this.equalizerShowPeak,
        equalizerPeakDecay:      equalizerPeakDecay      ?? this.equalizerPeakDecay,
        showPlayhead:            showPlayhead            ?? this.showPlayhead,
        playheadStyle:           playheadStyle           ?? this.playheadStyle,
        mirrorReflectionOpacity: mirrorReflectionOpacity ?? this.mirrorReflectionOpacity,
      );
}

/// Playhead cursor style.
enum PlayheadStyle {
  /// Simple vertical line.
  line,

  /// Line + triangles at top and bottom.
  arrows,

  /// Circle on the centre axis.
  circle,
}

// ─────────────────────────────────────────────────────────────────────────────
//  WaveformPainter
// ─────────────────────────────────────────────────────────────────────────────

class WaveformPainter extends CustomPainter {
  final WaveformData waveform;
  final RecorderConfig config;
  final WaveformStyleConfig styleConfig;
  final double playbackProgress;
  final bool isRecording;
  final bool isPlaying;
  final double currentAmplitude;
  final WaveformStyle style;

  // Peak memory for equalizer style (mutable, updated each paint)
  final List<double> _peaks;

  WaveformPainter({
    required this.waveform,
    required this.config,
    this.styleConfig      = const WaveformStyleConfig(),
    this.playbackProgress = 0.0,
    this.isRecording      = false,
    this.isPlaying        = false,
    this.currentAmplitude = 0.0,
    this.style            = WaveformStyle.bars,
    List<double>? peaks,
  }) : _peaks = peaks ?? [];

  // ── Entry point ──────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    switch (style) {
      case WaveformStyle.bars:      _drawBars(canvas, size);
      case WaveformStyle.mirror:    _drawMirror(canvas, size);
      case WaveformStyle.line:      _drawLine(canvas, size);
      case WaveformStyle.equalizer: _drawEqualizer(canvas, size);
      case WaveformStyle.radial:    _drawRadial(canvas, size);
      case WaveformStyle.wave:      _drawWave(canvas, size);
      case WaveformStyle.dots:      _drawDots(canvas, size);
      case WaveformStyle.neon:      _drawNeon(canvas, size);
      case WaveformStyle.stacked:   _drawStacked(canvas, size);
      case WaveformStyle.pixel:     _drawPixel(canvas, size);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ① BARS  — WhatsApp / Telegram
  // ─────────────────────────────────────────────────────────────────────────

  void _drawBars(Canvas canvas, Size size) {
    final stride  = config.barWidth + config.barGap;
    final maxBars = (size.width / stride).floor();
    final minH    = size.height * config.minBarHeightFraction;
    final centerY = size.height / 2;
    final samples = waveform.resample(maxBars);

    for (int i = 0; i < maxBars; i++) {
      final amp  = i < samples.length ? samples[i] : 0.0;
      final barH = (minH + amp * (size.height - minH)).clamp(minH, size.height);
      final x    = i * stride;
      final paint = _barPaint(i, maxBars, amp);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + config.barWidth / 2, centerY),
              width: config.barWidth, height: barH),
          Radius.circular(config.barBorderRadius),
        ),
        paint,
      );
    }

    if (isRecording) _drawLiveBar(canvas, size, maxBars * stride, minH, size.height);
    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ② MIRROR  — Spotify
  // ─────────────────────────────────────────────────────────────────────────

  void _drawMirror(Canvas canvas, Size size) {
    final stride  = config.barWidth + config.barGap;
    final maxBars = (size.width / stride).floor();
    final halfH   = size.height / 2;
    final minH    = halfH * config.minBarHeightFraction;
    final samples = waveform.resample(maxBars);

    for (int i = 0; i < maxBars; i++) {
      final amp  = i < samples.length ? samples[i] : 0.0;
      final barH = (minH + amp * (halfH - minH)).clamp(minH, halfH);
      final cx   = i * stride + config.barWidth / 2;
      final basePaint = _barPaint(i, maxBars, amp);

      // Top bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - config.barWidth / 2, halfH - barH, config.barWidth, barH),
          Radius.circular(config.barBorderRadius),
        ),
        basePaint,
      );
      // Bottom mirror — faded
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - config.barWidth / 2, halfH, config.barWidth, barH),
          Radius.circular(config.barBorderRadius),
        ),
        Paint()
          ..color = basePaint.color.withOpacity(styleConfig.mirrorReflectionOpacity)
          ..shader = basePaint.shader,
      );
    }

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ③ LINE  — SoundCloud closed fill
  // ─────────────────────────────────────────────────────────────────────────

  void _drawLine(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final samples = waveform.resample(size.width.toInt());
    final centerY = size.height / 2;
    final path    = _buildLinePath(samples, size, centerY);

    _paintSplitPath(canvas, size, path,
        playedPaint: Paint()
          ..color = config.playedColor.withOpacity(0.75)
          ..shader = styleConfig.useGradient
              ? _vertGradient(styleConfig.gradientColors, size, opacity: 0.75) : null,
        idlePaint: Paint()
          ..color = config.idleColor.withOpacity(0.45)
          ..shader = styleConfig.useGradient
              ? _vertGradient(styleConfig.idleGradientColors, size, opacity: 0.45) : null);

    canvas.drawPath(path,
        Paint()
          ..color = isRecording ? config.recordingColor : config.idleColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round);

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  Path _buildLinePath(List<double> samples, Size size, double centerY) {
    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final x = (i / samples.length) * size.width;
      final h = samples[i] * centerY * 0.92;
      if (i == 0) {
        path.moveTo(x, centerY - h);
      } else {
        path.lineTo(x, centerY - h);
      }
    }
    for (int i = samples.length - 1; i >= 0; i--) {
      final x = (i / samples.length) * size.width;
      final h = samples[i] * centerY * 0.92;
      path.lineTo(x, centerY + h);
    }
    path.close();
    return path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ④ EQUALIZER  — bottom-anchored bars + peak dots
  // ─────────────────────────────────────────────────────────────────────────

  void _drawEqualizer(Canvas canvas, Size size) {
    final stride  = config.barWidth + config.barGap;
    final maxBars = (size.width / stride).floor();
    final samples = waveform.resample(maxBars);
    final minH    = size.height * config.minBarHeightFraction;

    // Grow peaks list if needed
    while (_peaks.length < maxBars) {
      _peaks.add(0.0);
    }

    for (int i = 0; i < maxBars; i++) {
      final amp  = i < samples.length ? samples[i] : 0.0;
      final barH = (minH + amp * (size.height * 0.9 - minH)).clamp(minH, size.height * 0.9);
      final x    = i * stride;

      // Update peak with decay
      if (amp > _peaks[i]) {
        _peaks[i] = amp;
      } else {
        _peaks[i] *= styleConfig.equalizerPeakDecay;
      }

      // Bar with optional gradient (green → yellow → red from bottom to top)
      Paint barPaint;
      if (styleConfig.useGradient) {
        barPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end:   Alignment.topCenter,
            colors: [
              Color(0xFF43A047),
              Color(0xFFFDD835),
              Color(0xFFE53935),
            ],
            stops: [0.0, 0.65, 1.0],
          ).createShader(Rect.fromLTWH(x, 0, config.barWidth, size.height));
      } else {
        barPaint = Paint()..color = _barColorRaw(i, maxBars);
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH, config.barWidth, barH),
          Radius.circular(config.barBorderRadius),
        ),
        barPaint,
      );

      // Peak dot
      if (styleConfig.equalizerShowPeak && _peaks[i] > 0.02) {
        final peakH = (minH + _peaks[i] * (size.height * 0.9 - minH)).clamp(minH, size.height);
        final peakY = size.height - peakH - 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, peakY, config.barWidth, 3),
            const Radius.circular(1.5),
          ),
          Paint()..color = Colors.white.withOpacity(0.9),
        );
      }
    }

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑤ RADIAL  — circular bars from centre
  // ─────────────────────────────────────────────────────────────────────────

  void _drawRadial(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    final innerR    = maxRadius * styleConfig.radialInnerFraction;
    const maxBars   = 120;
    final samples   = waveform.resample(maxBars);
    final angleStep = (2 * pi) / maxBars;

    for (int i = 0; i < maxBars; i++) {
      final amp    = i < samples.length ? samples[i] : 0.0;
      final barLen = (amp * (maxRadius - innerR)).clamp(2.0, maxRadius - innerR);
      final angle  = i * angleStep - pi / 2; // start at top

      final startX = center.dx + innerR * cos(angle);
      final startY = center.dy + innerR * sin(angle);
      final endX   = center.dx + (innerR + barLen) * cos(angle);
      final endY   = center.dy + (innerR + barLen) * sin(angle);

      final fraction = i / maxBars;
      Color c;
      if (isRecording) {
        c = Color.lerp(config.recordingColor, config.recordingColor.withOpacity(0.4),
            amp < 0.1 ? 0.8 : 0.0)!;
      } else if (fraction <= playbackProgress) {
        c = styleConfig.useGradient
            ? Color.lerp(styleConfig.gradientColors.first,
                styleConfig.gradientColors.last, fraction)!
            : config.playedColor;
      } else {
        c = config.idleColor;
      }

      final strokePaint = Paint()
        ..color       = c
        ..strokeWidth = config.barWidth
        ..strokeCap   = styleConfig.radialRoundedTips ? StrokeCap.round : StrokeCap.butt;

      if (styleConfig.glowRadius > 0 && isRecording) {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY),
            Paint()
              ..color       = c.withOpacity(0.25)
              ..strokeWidth = config.barWidth * 3
              ..strokeCap   = StrokeCap.round
              ..maskFilter  = MaskFilter.blur(BlurStyle.normal, styleConfig.glowRadius));
      }
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), strokePaint);
    }

    // Inner circle
    canvas.drawCircle(center, innerR - 2,
        Paint()..color = config.backgroundColor.withOpacity(0.7));
    canvas.drawCircle(center, innerR - 2,
        Paint()
          ..color = (isRecording ? config.recordingColor : config.playedColor).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑥ WAVE  — smooth cubic bezier with gradient layers
  // ─────────────────────────────────────────────────────────────────────────

  void _drawWave(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final count   = (size.width / 2).toInt();
    final samples = waveform.resample(count);
    final centerY = size.height / 2;

    for (int layer = styleConfig.waveLayerCount - 1; layer >= 0; layer--) {
      final t          = layer / max(styleConfig.waveLayerCount - 1, 1);
      final vertOffset = layer * styleConfig.waveLayerOffset * size.height;
      final opacity    = 0.25 + (1 - t) * 0.55;
      final scale      = 0.6 + t * 0.4;

      final topPath    = Path();
      final bottomPath = Path();

      for (int i = 0; i < count; i++) {
        final x  = (i / count) * size.width;
        final h  = samples[i] * centerY * 0.88 * scale;
        final y  = centerY - h + vertOffset;
        final y2 = centerY + h + vertOffset;
        if (i == 0) { topPath.moveTo(x, y); bottomPath.moveTo(x, y2); }
        else if (i % 2 == 0) {
          final px = ((i - 1) / count) * size.width;
          final ph = samples[i - 1] * centerY * 0.88 * scale;
          topPath.quadraticBezierTo(px, centerY - ph + vertOffset, x, y);
          bottomPath.quadraticBezierTo(px, centerY + ph + vertOffset, x, y2);
        }
      }

      // Close shape
      final closedPath = Path()..addPath(topPath, Offset.zero);
      for (int i = count - 1; i >= 0; i--) {
        final x = (i / count) * size.width;
        final h = samples[i] * centerY * 0.88 * scale;
        closedPath.lineTo(x, centerY + h + vertOffset);
      }
      closedPath.close();

      final baseColor = isRecording ? config.recordingColor : config.playedColor;
      final Paint fillPaint;

      if (styleConfig.useGradient) {
        fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [
              styleConfig.gradientColors.first.withOpacity(opacity),
              styleConfig.gradientColors.last.withOpacity(opacity * 0.4),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      } else {
        fillPaint = Paint()..color = baseColor.withOpacity(opacity * (layer == 0 ? 1.0 : 0.55));
      }

      canvas.drawPath(closedPath, fillPaint);
      // Stroke top edge of foreground layer
      if (layer == 0) {
        canvas.drawPath(topPath,
            Paint()
              ..color       = baseColor.withOpacity(0.85)
              ..style       = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..strokeJoin  = StrokeJoin.round);
      }
    }

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑦ DOTS  — LED dot matrix
  // ─────────────────────────────────────────────────────────────────────────

  void _drawDots(Canvas canvas, Size size) {
    final rows    = styleConfig.dotRows;
    final stride  = config.barWidth + config.barGap;
    final cols    = (size.width / stride).floor();
    final cellH   = size.height / rows;
    final r       = min(config.barWidth, cellH) * 0.42;
    final samples = waveform.resample(cols);

    for (int col = 0; col < cols; col++) {
      final amp     = col < samples.length ? samples[col] : 0.0;
      final litRows = (amp * rows).round().clamp(1, rows);
      final cx      = col * stride + config.barWidth / 2;
      final fraction = col / cols;

      for (int row = 0; row < rows; row++) {
        final cy     = size.height - (row + 0.5) * cellH;
        final isLit  = row < litRows;
        final rowFrac = row / rows; // 0 = bottom, 1 = top

        Color dotColor;
        if (!isLit) {
          dotColor = config.idleColor.withOpacity(0.18);
        } else if (isRecording) {
          dotColor = styleConfig.useGradient
              ? Color.lerp(
                  styleConfig.gradientColors.first,
                  styleConfig.gradientColors.last, rowFrac)!
              : config.recordingColor;
        } else if (fraction <= playbackProgress) {
          dotColor = styleConfig.useGradient
              ? Color.lerp(
                  styleConfig.gradientColors.first,
                  styleConfig.gradientColors.last, rowFrac)!
              : config.playedColor;
        } else {
          dotColor = config.idleColor.withOpacity(0.55);
        }

        final paint = styleConfig.dotFilled
            ? (Paint()..color = dotColor)
            : (Paint()
              ..color       = dotColor
              ..style       = PaintingStyle.stroke
              ..strokeWidth = 1.0);

        canvas.drawCircle(Offset(cx, cy), r, paint);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑧ NEON  — glowing bars with bloom
  // ─────────────────────────────────────────────────────────────────────────

  void _drawNeon(Canvas canvas, Size size) {
    final stride  = config.barWidth + config.barGap;
    final maxBars = (size.width / stride).floor();
    final minH    = size.height * config.minBarHeightFraction;
    final centerY = size.height / 2;
    final samples = waveform.resample(maxBars);

    for (int i = 0; i < maxBars; i++) {
      final amp  = i < samples.length ? samples[i] : 0.0;
      final barH = (minH + amp * (size.height - minH)).clamp(minH, size.height);
      final x    = i * stride;
      final rect = Rect.fromCenter(
          center: Offset(x + config.barWidth / 2, centerY),
          width: config.barWidth, height: barH);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(config.barBorderRadius));

      final baseColor = _barColorRaw(i, maxBars);

      // Multi-layer glow (outer → inner)
      for (int g = styleConfig.glowLayers; g >= 0; g--) {
        final blurSigma = styleConfig.glowRadius * (g + 1) / styleConfig.glowLayers;
        final glowOpacity = (0.08 + 0.1 * (1 - g / styleConfig.glowLayers)) *
            (amp + 0.1).clamp(0, 1);
        canvas.drawRRect(rrect,
            Paint()
              ..color      = baseColor.withOpacity(glowOpacity)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma));
      }

      // Solid core bar
      canvas.drawRRect(rrect, Paint()..color = baseColor);

      // Bright centre highlight
      if (amp > 0.05) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(x + config.barWidth / 2, centerY),
                width: config.barWidth * 0.35, height: barH * 0.85),
            Radius.circular(config.barBorderRadius),
          ),
          Paint()..color = Colors.white.withOpacity(0.55 * amp),
        );
      }
    }

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑨ STACKED  — layered semi-transparent waves (holographic)
  // ─────────────────────────────────────────────────────────────────────────

  void _drawStacked(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final count    = (size.width / 2).toInt();
    final samples  = waveform.resample(count);
    final layers   = styleConfig.waveLayerCount;
    final baseColor = isRecording ? config.recordingColor : config.playedColor;

    for (int layer = layers - 1; layer >= 0; layer--) {
      final t        = layer / max(layers - 1, 1);
      final yShift   = (layer - layers / 2) * styleConfig.waveLayerOffset * size.height;
      final opacity  = 0.12 + (1 - t) * 0.45;
      final scale    = 0.55 + t * 0.45;
      final hueShift = layer * 15.0;

      final layerColor = styleConfig.useGradient
          ? Color.lerp(styleConfig.gradientColors.first,
              styleConfig.gradientColors.last, t)!.withOpacity(opacity)
          : _shiftHue(baseColor, hueShift).withOpacity(opacity);

      final path = _buildSmoothedPath(samples, size, scale, yShift);

      canvas.drawPath(path, Paint()..color = layerColor);
      canvas.drawPath(
          path,
          Paint()
            ..color       = layerColor.withOpacity(opacity * 1.5)
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }

    if (styleConfig.showPlayhead && (isPlaying || playbackProgress > 0)) {
      _drawPlayhead(canvas, size, playbackProgress * size.width);
    }
  }

  Path _buildSmoothedPath(List<double> samples, Size size, double scale, double yShift) {
    final centerY = size.height / 2 + yShift;
    final count   = samples.length;
    final path    = Path();

    for (int i = 0; i < count; i++) {
      final x = (i / count) * size.width;
      final h = samples[i] * centerY * 0.85 * scale;
      if (i == 0) {
        path.moveTo(x, centerY - h);
      } else {
        final px = ((i - 1) / count) * size.width;
        final ph = samples[i - 1] * centerY * 0.85 * scale;
        path.quadraticBezierTo(px, centerY - ph, x, centerY - h);
      }
    }
    for (int i = count - 1; i >= 0; i--) {
      final x = (i / count) * size.width;
      final h = samples[i] * centerY * 0.85 * scale;
      path.lineTo(x, centerY + h);
    }
    path.close();
    return path;
  }

  Color _shiftHue(Color color, double hueDelta) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hueDelta) % 360).toColor();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ⑩ PIXEL  — retro blocky grid cells
  // ─────────────────────────────────────────────────────────────────────────

  void _drawPixel(Canvas canvas, Size size) {
    final rows    = styleConfig.pixelRows;
    final gap     = styleConfig.pixelGap;
    final stride  = config.barWidth + config.barGap;
    final cols    = (size.width / stride).floor();
    final cellH   = (size.height - gap * (rows + 1)) / rows;
    final samples = waveform.resample(cols);

    for (int col = 0; col < cols; col++) {
      final amp     = col < samples.length ? samples[col] : 0.0;
      final litRows = (amp * rows).round().clamp(1, rows);
      final fraction = col / cols;
      final cx      = col * stride;

      for (int row = 0; row < rows; row++) {
        final cy     = size.height - gap - (row + 1) * (cellH + gap);
        final isLit  = row < litRows;
        final rowFrac = row / rows;

        Color cellColor;
        if (!isLit) {
          cellColor = config.idleColor.withOpacity(0.10);
        } else if (isRecording) {
          // Recording: green → yellow → red (bottom to top)
          cellColor = Color.lerp(
            const Color(0xFF43A047),
            rowFrac > 0.7 ? const Color(0xFFE53935) : const Color(0xFFFDD835),
            (rowFrac - 0.0).clamp(0.0, 1.0),
          )!;
        } else if (fraction <= playbackProgress) {
          cellColor = styleConfig.useGradient
              ? Color.lerp(
                  styleConfig.gradientColors.first,
                  styleConfig.gradientColors.last, rowFrac)!
              : config.playedColor;
        } else {
          cellColor = config.idleColor.withOpacity(0.5);
        }

        canvas.drawRect(
          Rect.fromLTWH(cx, cy, config.barWidth, cellH),
          Paint()..color = cellColor,
        );
        // Inner highlight pixel
        if (isLit) {
          canvas.drawRect(
            Rect.fromLTWH(cx + 0.5, cy + 0.5, config.barWidth * 0.4, 1.5),
            Paint()..color = Colors.white.withOpacity(0.35),
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Shared helpers
  // ─────────────────────────────────────────────────────────────────────────

  Paint _barPaint(int index, int total, double amp) {
    final color = _barColorRaw(index, total);
    if (!styleConfig.useGradient) return Paint()..color = color;

    final size = Size(config.barWidth, amp * 200); // approximate
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end:   Alignment.bottomCenter,
        colors: index / total <= playbackProgress
            ? styleConfig.gradientColors
            : styleConfig.idleGradientColors,
      ).createShader(Rect.fromLTWH(0, 0, config.barWidth, size.height));
  }

  Color _barColorRaw(int index, int total) {
    if (isRecording) return config.recordingColor;
    if (total == 0)  return config.idleColor;
    return index / total <= playbackProgress ? config.playedColor : config.idleColor;
  }

  void _drawLiveBar(Canvas canvas, Size size, double x, double minH, double maxH) {
    if (x >= size.width) return;
    final barH = (minH + currentAmplitude * (maxH - minH)).clamp(minH, maxH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x + config.barWidth / 2, size.height / 2),
            width: config.barWidth * 1.5, height: barH),
        Radius.circular(config.barBorderRadius),
      ),
      Paint()..color = config.recordingColor,
    );
  }

  void _drawPlayhead(Canvas canvas, Size size, double x) {
    final color = config.playedColor;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height),
        Paint()..color = color..strokeWidth = 1.5);

    switch (styleConfig.playheadStyle) {
      case PlayheadStyle.line:
        break;
      case PlayheadStyle.arrows:
        // Top ▼
        canvas.drawPath(
            Path()..moveTo(x - 5, 0)..lineTo(x + 5, 0)..lineTo(x, 8)..close(),
            Paint()..color = color);
        // Bottom ▲
        canvas.drawPath(
            Path()..moveTo(x - 5, size.height)..lineTo(x + 5, size.height)
                ..lineTo(x, size.height - 8)..close(),
            Paint()..color = color);
      case PlayheadStyle.circle:
        canvas.drawCircle(Offset(x, size.height / 2), 6,
            Paint()..color = color);
        canvas.drawCircle(Offset(x, size.height / 2), 6,
            Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  void _paintSplitPath(
    Canvas canvas, Size size, Path path, {
    required Paint playedPaint,
    required Paint idlePaint,
  }) {
    if (playbackProgress > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, playbackProgress * size.width, size.height));
      canvas.drawPath(path, playedPaint);
      canvas.restore();
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
        playbackProgress * size.width, 0,
        size.width * (1 - playbackProgress), size.height));
    canvas.drawPath(path, idlePaint);
    canvas.restore();
  }

  Shader _vertGradient(List<Color> colors, Size size, {double opacity = 1.0}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end:   Alignment.bottomCenter,
      colors: colors.map((c) => c.withOpacity(opacity)).toList(),
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.waveform != waveform ||
      old.playbackProgress != playbackProgress ||
      old.isRecording != isRecording ||
      old.isPlaying != isPlaying ||
      old.currentAmplitude != currentAmplitude ||
      old.style != style ||
      old.styleConfig != styleConfig;
}
