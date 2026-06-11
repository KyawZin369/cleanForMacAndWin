import 'dart:io';

import 'package:mole_ui/core/platform/platform_info.dart';

class MoleCliNotFoundException implements Exception {
  const MoleCliNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves the Mole / WinMole CLI entry point for the current platform.
class MoleCliLocator {
  MoleCliLocator._();

  static String? _cachedMacPath;
  static String? _cachedMacRoot;
  static String? _cachedWindowsScript;

  static const macBundledRelativePath = 'Resources/mole/mo';
  static const windowsBundledRelativePath = 'winmole/winmole.ps1';
  static const windowsScriptName = 'winmole.ps1';

  static const macInstallCandidates = [
    '/opt/homebrew/bin/mo',
    '/usr/local/bin/mo',
  ];

  static const brewInstallCommand = 'brew install mole';
  static const winMoleInstallCommand =
      r'powershell -ExecutionPolicy Bypass -File .\install.ps1 -AddToPath';

  static const macInstallHint =
      'Rebuild the app to restore the bundled Mole runtime.';
  static const windowsInstallHint =
      'Run scripts/setup_winmole_vendor.sh, then rebuild the Windows app.';

  static String get installHint => switch (currentPlatform) {
        AppPlatform.mac => macInstallHint,
        AppPlatform.windows => windowsInstallHint,
        AppPlatform.unsupported => 'Unsupported platform.',
      };

  static void clearCache() {
    _cachedMacPath = null;
    _cachedMacRoot = null;
    _cachedWindowsScript = null;
  }

  static Future<String> resolveExecutable() async {
    switch (currentPlatform) {
      case AppPlatform.mac:
        return _resolveMacExecutable();
      case AppPlatform.windows:
        final script = await _resolveWindowsScript();
        return script!;
      case AppPlatform.unsupported:
        throw UnsupportedError(
          'CLI is only supported on macOS and Windows.',
        );
    }
  }

  static Future<String?> tryResolveExecutable() async {
    return switch (currentPlatform) {
      AppPlatform.mac => () async {
          final path = await _resolveMacExecutable(throwIfMissing: false);
          return path.isEmpty ? null : path;
        }(),
      AppPlatform.windows => _resolveWindowsScript(throwIfMissing: false),
      AppPlatform.unsupported => null,
    };
  }

  static Future<bool> isBundledRuntimeAvailable() async {
    return switch (currentPlatform) {
      AppPlatform.mac => (await _resolveBundledMacExecutable()) != null,
      AppPlatform.windows => (await _resolveBundledWindowsScript()) != null,
      AppPlatform.unsupported => false,
    };
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

  static Future<bool> isWinMoleOnPath() async {
    if (currentPlatform != AppPlatform.windows) return false;

    final result = await Process.run(
      'where',
      ['winmole'],
      runInShell: true,
    );
    if (result.exitCode != 0) return false;
    final output = (result.stdout as String? ?? '').trim();
    return output.isNotEmpty;
  }

  static Future<String?> bundledMoleRoot() async {
    return switch (currentPlatform) {
      AppPlatform.mac => _bundledMacRoot(),
      AppPlatform.windows => _bundledWindowsRoot(),
      AppPlatform.unsupported => null,
    };
  }

  /// Builds the process invocation for CLI commands on the current platform.
  static Future<CliLaunchSpec> buildLaunchSpec(List<String> args) async {
    return switch (currentPlatform) {
      AppPlatform.mac => CliLaunchSpec(
          executable: await resolveExecutable(),
          args: args,
          environment: await macProcessEnvironment(),
          runInShell: false,
        ),
      AppPlatform.windows => () async {
          final script = await resolveExecutable();
          return CliLaunchSpec(
            executable: 'powershell.exe',
            args: [
              '-NoProfile',
              '-ExecutionPolicy',
              'Bypass',
              '-File',
              script,
              ...args,
            ],
            environment: await windowsProcessEnvironment(),
            runInShell: false,
          );
        }(),
      AppPlatform.unsupported => throw UnsupportedError(
          'CLI is only supported on macOS and Windows.',
        ),
    };
  }

  static Future<String?> _bundledMacRoot() async {
    final cached = _cachedMacRoot;
    if (cached != null && await Directory(cached).exists()) {
      return cached;
    }

    final executable = await _resolveBundledMacExecutable();
    if (executable == null) return null;

    final root = File(executable).parent.path;
    _cachedMacRoot = root;
    return root;
  }

  static Future<String?> _bundledWindowsRoot() async {
    final script = await _resolveBundledWindowsScript();
    if (script == null) return null;
    return File(script).parent.path;
  }

  static Future<String> _resolveMacExecutable({bool throwIfMissing = true}) async {
    final cached = _cachedMacPath;
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    final bundled = await _resolveBundledMacExecutable();
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
      throw MoleCliNotFoundException(
        'Mole CLI (mo) was not found. $macInstallHint',
      );
    }
    return '';
  }

  static Future<String?> _resolveWindowsScript({bool throwIfMissing = true}) async {
    final cached = _cachedWindowsScript;
    if (cached != null && await File(cached).exists()) {
      return cached;
    }

    final bundled = await _resolveBundledWindowsScript();
    if (bundled != null) {
      _cachedWindowsScript = bundled;
      return bundled;
    }

    final vendorScript = await _resolveVendorWindowsScript();
    if (vendorScript != null) {
      _cachedWindowsScript = vendorScript;
      return vendorScript;
    }

    final pathScript = await _resolveWindowsScriptFromPath();
    if (pathScript != null) {
      _cachedWindowsScript = pathScript;
      return pathScript;
    }

    if (throwIfMissing) {
      throw MoleCliNotFoundException(
        'WinMole (winmole.ps1) was not found. $windowsInstallHint',
      );
    }
    return null;
  }

  static Future<String?> _resolveBundledMacExecutable() async {
    final executable = Platform.resolvedExecutable;
    final bundleMo = File(
      '${File(executable).parent.parent.path}/$macBundledRelativePath',
    );
    if (await bundleMo.exists()) {
      return bundleMo.path;
    }

    return _resolveVendorMacExecutable();
  }

  static Future<String?> _resolveVendorMacExecutable() async {
    final vendorRoot = Platform.environment['MOLE_VENDOR_ROOT'];
    if (vendorRoot != null && vendorRoot.isNotEmpty) {
      final vendorMo = File('$vendorRoot/mo');
      if (await vendorMo.exists()) {
        return vendorMo.path;
      }
    }
    return null;
  }

  static Future<String?> _resolveBundledWindowsScript() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$exeDir/$windowsBundledRelativePath',
      '$exeDir/data/$windowsBundledRelativePath',
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    return _resolveVendorWindowsScript();
  }

  static Future<String?> _resolveVendorWindowsScript() async {
    for (final key in ['WINMOLE_VENDOR_ROOT', 'MOLE_VENDOR_ROOT']) {
      final vendorRoot = Platform.environment[key];
      if (vendorRoot == null || vendorRoot.isEmpty) continue;

      final script = File('$vendorRoot/$windowsScriptName');
      if (await script.exists()) {
        return script.path;
      }
    }
    return null;
  }

  static Future<String?> _resolveWindowsScriptFromPath() async {
    final result = await Process.run(
      'where',
      [windowsScriptName],
      runInShell: true,
    );
    if (result.exitCode != 0) return null;

    final lines = (result.stdout as String? ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    for (final line in lines) {
      if (await File(line).exists()) {
        return line;
      }
    }
    return null;
  }

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

    final moleRoot = await _bundledMacRoot();
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

  static Future<Map<String, String>> windowsProcessEnvironment() async {
    final env = Map<String, String>.from(Platform.environment);
    final root = await _bundledWindowsRoot();
    if (root != null) {
      env['WINMOLE_VENDOR_ROOT'] = root;
      final binDir = '$root\\bin';
      final path = env['PATH'] ?? '';
      if (!path.toLowerCase().contains(binDir.toLowerCase())) {
        env['PATH'] = '$binDir;$path';
      }
    }
    return env;
  }
}

class CliLaunchSpec {
  const CliLaunchSpec({
    required this.executable,
    required this.args,
    required this.environment,
    required this.runInShell,
  });

  final String executable;
  final List<String> args;
  final Map<String, String>? environment;
  final bool runInShell;
}
