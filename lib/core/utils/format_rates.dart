String formatBytesPerSecond(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 B/s';

  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var value = bytesPerSecond;
  var unit = 0;

  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }

  final digits = value >= 100 ? 0 : value >= 10 ? 1 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatMegabytesPerSecond(double mbPerSecond) {
  if (mbPerSecond <= 0) return '0 MB/s';
  if (mbPerSecond < 0.01) return '${(mbPerSecond * 1024).toStringAsFixed(2)} KB/s';
  return '${mbPerSecond.toStringAsFixed(mbPerSecond >= 10 ? 1 : 2)} MB/s';
}
