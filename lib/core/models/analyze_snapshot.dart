class AnalyzeEntry {
  const AnalyzeEntry({
    required this.name,
    required this.path,
    required this.size,
    required this.isDir,
    this.insight = false,
    this.cleanable = false,
  });

  final String name;
  final String path;
  final int size;
  final bool isDir;
  final bool insight;
  final bool cleanable;

  factory AnalyzeEntry.fromJson(Map<String, dynamic> json) {
    return AnalyzeEntry(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      isDir: json['is_dir'] as bool? ?? false,
      insight: json['insight'] as bool? ?? false,
      cleanable: json['cleanable'] as bool? ?? false,
    );
  }
}

class AnalyzeSnapshot {
  const AnalyzeSnapshot({
    required this.path,
    required this.overview,
    required this.entries,
    required this.totalSize,
  });

  final String path;
  final bool overview;
  final List<AnalyzeEntry> entries;
  final int totalSize;

  factory AnalyzeSnapshot.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? [])
        .map((item) => AnalyzeEntry.fromJson(item as Map<String, dynamic>))
        .where((entry) => entry.name.isNotEmpty && entry.path.isNotEmpty)
        .toList();

    return AnalyzeSnapshot(
      path: json['path'] as String? ?? '/',
      overview: json['overview'] as bool? ?? false,
      entries: entries,
      totalSize: json['total_size'] as int? ?? 0,
    );
  }
}
