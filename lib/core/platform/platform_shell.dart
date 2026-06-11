import 'dart:io' as io;

import 'package:mole_ui/core/platform/platform_info.dart';

class PlatformShell {
  PlatformShell._();

  static String get analyzeRootLabel =>
      isMacOS ? 'Macintosh HD' : 'This PC';

  static String get revealInExplorerLabel =>
      isMacOS ? 'Open in Finder' : 'Open in Explorer';

  static List<String> pathSegments(String path) {
    if (isMacOS) {
      if (path == '/') return [];
      return path.split('/').where((part) => part.isNotEmpty).toList();
    }

    final normalized = path.replaceAll('/', r'\');
    return normalized
        .split(r'\')
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static String? parentPath(String path) {
    if (isMacOS) {
      final normalized = path.replaceAll(RegExp(r'/+$'), '');
      if (normalized.isEmpty || normalized == '/') return null;
      final index = normalized.lastIndexOf('/');
      if (index <= 0) return null;
      return normalized.substring(0, index);
    }

    final normalized = path.replaceAll('/', r'\').replaceAll(RegExp(r'\\+$'), '');
    if (normalized.isEmpty) return null;
    if (RegExp(r'^[A-Za-z]:$').hasMatch(normalized)) return null;

    final index = normalized.lastIndexOf(r'\');
    if (index < 0) return null;
    if (index <= 2 && normalized.contains(':')) return null;
    return normalized.substring(0, index);
  }

  static String? breadcrumbPath(List<String> segments, int index) {
    if (index <= 0) return null;
    if (index >= segments.length) return null;

    if (isMacOS) {
      return '/${segments.sublist(1, index + 1).join('/')}';
    }

    final parts = segments.sublist(1, index + 1);
    if (parts.isEmpty) return null;
    if (parts.length == 1 && RegExp(r'^[A-Za-z]:$').hasMatch(parts.first)) {
      return '${parts.first}\\';
    }
    return parts.join(r'\');
  }

  static Future<int?> fetchFreeBytes() async {
    if (isMacOS) {
      final result = await io.Process.run('df', ['-k', '/']);
      final lines = (result.stdout as String? ?? '').split('\n');
      if (lines.length < 2) return null;

      final parts = lines[1].trim().split(RegExp(r'\s+'));
      if (parts.length < 4) return null;

      final availableKb = int.tryParse(parts[3]);
      return availableKb != null ? availableKb * 1024 : null;
    }

    final result = await io.Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-Command',
        r"(Get-PSDrive -PSProvider FileSystem | Sort-Object Used -Descending | Select-Object -First 1).Free",
      ],
      runInShell: false,
    );
    final text = (result.stdout as String? ?? '').trim();
    final freeBytes = int.tryParse(text);
    return freeBytes;
  }

  static Future<void> revealInFileManager(String path) async {
    if (path.isEmpty) return;

    if (isMacOS) {
      await io.Process.run('open', [path]);
      return;
    }

    final normalized = path.replaceAll('/', r'\');
    if (io.FileSystemEntity.typeSync(normalized) ==
        io.FileSystemEntityType.directory) {
      await io.Process.run('explorer.exe', [normalized]);
      return;
    }

    await io.Process.run(
      'explorer.exe',
      ['/select,', normalized],
      runInShell: true,
    );
  }
}
