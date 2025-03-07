/// Formats seconds to always show 2 decimal places for display purposes
String formatSecondsDisplay(double seconds) {
  return seconds.toStringAsFixed(2);
}

/// Formats seconds to always show 4 decimal places for display purposes
String formatSecondsDetailedDisplay(double seconds) {
  return seconds.toStringAsFixed(4);
}

/// Formats a duration in seconds as MM:SS with 2 decimal places
String formatDurationMMSS(double seconds, {bool detailed = false}) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  final secondsStr = detailed
      ? remainingSeconds.toStringAsFixed(4)
      : remainingSeconds.toStringAsFixed(2);

  return '${minutes < 10 ? '0' : ''}$minutes:${remainingSeconds < 10 ? '0' : ''}$secondsStr';
}

/// Formats a duration in seconds as HH:MM:SS with optional decimal places
String formatDurationHHMMSS(double seconds, {bool detailed = false}) {
  int detailedMs = 3;
  int simpleMs = 2;

  if (seconds < 60) {
    return detailed
        ? '${seconds.toStringAsFixed(detailedMs)}s'
        : '${seconds.toStringAsFixed(simpleMs)}s';
  }
  if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final secondsStr = detailed
        ? remainingSeconds.toStringAsFixed(detailedMs)
        : remainingSeconds.toStringAsFixed(simpleMs);
    return '${minutes < 10 ? '0' : ''}$minutes:${remainingSeconds < 10 ? '0' : ''}$secondsStr${detailed ? 's' : ''}';
  }
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  final secondsStr = detailed
      ? remainingSeconds.toStringAsFixed(detailedMs)
      : remainingSeconds.toStringAsFixed(simpleMs);
  return '${hours < 10 ? '0' : ''}$hours:${minutes < 10 ? '0' : ''}$minutes:${remainingSeconds < 10 ? '0' : ''}$secondsStr${detailed ? 's' : ''}';
}

/// Formats a Duration object as HH:MM:SS
String formatDurationObject(Duration duration) {
  String twoDigits(dynamic n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

/// Formats a duration in seconds with words (hours/minutes/seconds)
String formatDurationWords(double seconds) {
  if (seconds < 60) {
    return '${formatSecondsDisplay(seconds)} seconds';
  }
  if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes ${minutes == 1 ? "minute" : "minutes"} ${remainingSeconds.toStringAsFixed(2)} seconds';
  }
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '$hours ${hours == 1 ? "hour" : "hours"} $minutes ${minutes == 1 ? "minute" : "minutes"}';
}
