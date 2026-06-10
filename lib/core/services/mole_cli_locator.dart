import 'dart:io';

import 'package:mole_ui/core/platform/platform_info.dart';

class MoleCliNotFoundException implements Exception {
  const MoleCliNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves the Mole CLI binary, preferring the copy bundled inside the app.
class MoleCliLocator {
  MoleCliLocator._();

  static String? _cachedMacPath;
  static String? _cachedMacRoot;

  static const bundledRelativePath = 'Resources/mole/mo';

  static const macInstallCandidates = [
    '/opt/homebrew/bin/mo',
    '/usr/local/bin/mo',
  ];

  static const brewInstallCommand = 'brew install mole';

  static const installHint =
      'Rebuild the app to restore the bundled Mole runtime.';

  static void clearCache() {
    _cachedMacPath = null;
    _cachedMacRoot = null;
  }

  static Future<String> resolveExecutable() async {
    return switch (currentPlatform) {
      AppPlatform.mac => _resolveMacExecutable(),
      AppPlatform.windows => 'winmole',
      AppPlatform.unsupported => throw UnsupportedError(
          'Mole CLI is only supported on macOS and Windows.',
        ),
    };
  }

  static Future<String?> tryResolveExecutable() async {
    return switch (currentPlatform) {
      AppPlatform.mac => () async {
          final path = await _resolveMacExecutable(throwIfMissing: false);
          return path.isEmpty ? null : path;
        }(),
      AppPlatform.windows => 'winmole',
      AppPlatform.unsupported => null,
    };
  }

  static Future<bool> isBundledRuntimeAvailable() async {
    if (currentPlatform != AppPlatform.mac) return false;
    final bundled = await _resolveBundledExecutable();
    return bundled != null;
  }

  static Future<bool> isHomebrewInstalled() async {
    if (currentPlatform != AppPlatform.mac) return false;

    for (final path in ['/opt/homebrew/bin/brew', '/usr/local/bin/brew']) {
      if (await File(path).exists()) return true;
    }

    final result = await Process.run(
      '/bin/zsh',
      ['-l', '-c', 'command -v brew'],
      stdoutEncoding: null,
      stderrEncoding: null,
    );
    if (result.exitCode != 0) return false;
    final path = String.fromCharCodes(result.stdout as List<int>).trim();
    return path.isNotEmpty && await File(path).exists();
  }

  static Future<String?> bundledMoleRoot() async {
    final cached = _cachedMacRoot;
    if (cached != null && await Directory(cached).exists()) {
      return cached;
    }

    final executable = await _resolveBundledExecutable();
    if (executable == null) return null;

    final root = File(executable).parent.path;
    _cachedMacRoot = root;
    return root;
  }

  static Future<String> _resolveMacExecutable({bool throwIfMissing = true}) async {
    final cached = _cachedMacPath;
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    final bundled = await _resolveBundledExecutable();
    if (bundled != null) {
      _cachedMacPath = bundled;
      _cachedMacRoot = File(bundled).parent.path;
      return bundled;
    }

    for (final path in macInstallCandidates) {
      if (await File(path).exists()) {
        _cachedMacPath = path;
        return path;
      }
    }

    final result = await Process.run(
      '/bin/zsh',
      ['-l', '-c', 'command -v mo'],
      stdoutEncoding: null,
      stderrEncoding: null,
    );
    final path = String.fromCharCodes(result.stdout as List<int>).trim();
    if (result.exitCode == 0 && path.isNotEmpty && await File(path).exists()) {
      _cachedMacPath = path;
      return path;
    }

    if (throwIfMissing) {
      throw const MoleCliNotFoundException(
        'Mole CLI (mo) was not found. $installHint',
      );
    }
    return '';
  }

  static Future<String?> _resolveBundledExecutable() async {
    final executable = Platform.resolvedExecutable;
    final bundleMo = File(
      '${File(executable).parent.parent.path}/$bundledRelativePath',
    );
    if (await bundleMo.exists()) {
      return bundleMo.path;
    }

    final vendorRoot = Platform.environment['MOLE_VENDOR_ROOT'];
    if (vendorRoot != null && vendorRoot.isNotEmpty) {
      final vendorMo = File('$vendorRoot/mo');
      if (await vendorMo.exists()) {
        return vendorMo.path;
      }
    }

    return null;
  }

  /// GUI apps often launch with a minimal PATH; ensure tool dirs are present.
  static Future<Map<String, String>> macProcessEnvironment() async {
    final env = Map<String, String>.from(Platform.environment);
    const pathPrefixes = [
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
    ];

    final parts = (env['PATH'] ?? '/usr/bin:/bin')
        .split(':')
        .where((part) => part.isNotEmpty)
        .toList();

    final moleRoot = await bundledMoleRoot();
    if (moleRoot != null) {
      final moleBin = '$moleRoot/bin';
      if (!parts.contains(moleBin)) {
        parts.insert(0, moleBin);
      }
      env['MOLE_VENDOR_ROOT'] = moleRoot;
    }

    for (final prefix in pathPrefixes.reversed) {
      if (!parts.contains(prefix)) {
        parts.insert(0, prefix);
      }
    }

    env['PATH'] = parts.join(':');
    return env;
  }
}
