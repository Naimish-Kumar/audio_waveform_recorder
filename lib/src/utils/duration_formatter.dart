/// Formats Duration values for display in the recorder/player UI.
class DurationFormatter {
  /// Format as MM:SS or HH:MM:SS if >= 1 hour.
  static String format(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// Format as MM:SS.mmm (with milliseconds) for precise display.
  static String formatPrecise(Duration duration) {
    final m  = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  /// Format file size in human-readable form.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  }
}
