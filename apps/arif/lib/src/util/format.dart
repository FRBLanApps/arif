String formatBytes(int bytes) {
  if (bytes < 0) bytes = 0;
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 ? 0 : (value >= 100 ? 0 : (value >= 10 ? 1 : 2));
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatSpeed(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';

String formatProgress(double progress) {
  final pct = (progress * 100).clamp(0, 100);
  if (pct >= 100) return '100%';
  if (pct >= 10) return '${pct.toStringAsFixed(1)}%';
  return '${pct.toStringAsFixed(2)}%';
}
