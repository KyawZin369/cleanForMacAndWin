class UninstallApp {
  const UninstallApp({
    required this.name,
    required this.bundleId,
    required this.source,
    required this.uninstallName,
    required this.path,
    required this.size,
  });

  final String name;
  final String bundleId;
  final String source;
  final String uninstallName;
  final String path;
  final String size;

  factory UninstallApp.fromJson(Map<String, dynamic> json) {
    return UninstallApp(
      name: json['name'] as String? ?? '',
      bundleId: json['bundle_id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      uninstallName: json['uninstall_name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      size: json['size'] as String? ?? '',
    );
  }
}

/// Converts size strings like `1.6MB` or `6.93GB` to bytes for sorting.
double sizeToBytes(String size) {
  final match = RegExp(
    r'^([\d.]+)\s*(KB|MB|GB|TB)?$',
    caseSensitive: false,
  ).firstMatch(size.trim());
  if (match == null) return 0;

  final value = double.tryParse(match.group(1)!) ?? 0;
  return switch (match.group(2)?.toUpperCase()) {
    'KB' => value * 1024,
    'MB' => value * 1024 * 1024,
    'GB' => value * 1024 * 1024 * 1024,
    'TB' => value * 1024 * 1024 * 1024 * 1024,
    _ => value,
  };
}
