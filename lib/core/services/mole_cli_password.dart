import 'dart:async';
import 'dart:io' as io;

import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';

class MolePasswordPrompt {
  const MolePasswordPrompt({
    required this.message,
    this.isRetry = false,
    this.errorMessage,
  });

  final String message;
  final bool isRetry;
  final String? errorMessage;
}

typedef MolePasswordPromptCallback = Future<String?> Function(
  MolePasswordPrompt prompt,
);

class MoleCliPassword {
  MoleCliPassword._();

  static final _ansiEscape = RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]');
  static io.Process? _sudoKeepaliveProcess;

  static final passwordPromptLine = RegExp(
    r'Password:\s*$|Enter your credentials|Admin access required',
    caseSensitive: false,
  );

  static final wrongPasswordLine = RegExp(
    r'Sorry, try again|incorrect password attempt',
    caseSensitive: false,
  );

  static final uninstallMatchedHeader = RegExp(
    r'Matched\s+\d+\s+app\(s\)',
    caseSensitive: false,
  );

  static final uninstallMatchedAppLine = RegExp(r'^\d+\.\s+');

  static final uninstallExecuteConfirm = RegExp(
    r'Enter.*confirm|Remove \d+ apps?',
    caseSensitive: false,
  );

  static final sudoSectionHeader = RegExp(
    r'^➤\s+(App caches|Developer tools|Virtualization|'
    r'Device backups & firmware|Time Machine|Large files|System Data clues)',
  );

  static String normalizeCliLine(String line) {
    return stripAnsi(line).trim();
  }

  static String stripAnsi(String line) {
    return line.replaceAll(_ansiEscape, '');
  }

  static bool isPasswordPromptLine(String line) {
    return passwordPromptLine.hasMatch(normalizeCliLine(line));
  }

  static bool isWrongPasswordLine(String line) {
    return wrongPasswordLine.hasMatch(normalizeCliLine(line));
  }

  static bool isSudoSectionHeader(String line) {
    return sudoSectionHeader.hasMatch(normalizeCliLine(line));
  }

  /// First prompt: `Proceed with uninstallation? [y/N]`.
  static bool isUninstallProceedPoint(String line) {
    final normalized = normalizeCliLine(line);
    return uninstallMatchedHeader.hasMatch(normalized) ||
        uninstallMatchedAppLine.hasMatch(normalized);
  }

  /// Second prompt: `Enter confirm, ESC cancel` (single keypress).
  static bool isUninstallExecutePoint(String line) {
    return uninstallExecuteConfirm.hasMatch(normalizeCliLine(line));
  }

  static bool isUninstallPreviewStart(String line) {
    return normalizeCliLine(line).contains('Files to be removed');
  }

  /// Printed just before mole requests sudo during uninstall.
  static bool isUninstallAdminRequired(String line) {
    return normalizeCliLine(line).contains('Admin required');
  }

  static Future<bool> hasActiveSudoSession({
    Map<String, String>? environment,
  }) async {
    if (currentPlatform != AppPlatform.mac) return false;

    final env = environment ?? await MoleCliLocator.macProcessEnvironment();
    final result = await io.Process.run(
      'sudo',
      ['-n', 'true'],
      environment: env,
    );
    return result.exitCode == 0;
  }

  static Future<bool> authenticateSudo(String password) async {
    final environment = await MoleCliLocator.macProcessEnvironment();
    final process = await io.Process.start(
      'sudo',
      ['-S', '-p', '', '-v'],
      environment: environment,
    );
    process.stdin.write('$password\n');
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode != 0) return false;

    return prepareForMoleCli();
  }

  /// Verifies sudo is cached for the Mole CLI environment and starts a
  /// keepalive so `mo` never blocks on `/dev/tty` password prompts.
  static Future<bool> prepareForMoleCli() async {
    if (currentPlatform != AppPlatform.mac) return true;

    final environment = await MoleCliLocator.macProcessEnvironment();
    if (!await hasActiveSudoSession(environment: environment)) {
      return false;
    }

    final refresh = await io.Process.run(
      'sudo',
      ['-n', '-v'],
      environment: environment,
    );
    if (refresh.exitCode != 0) {
      return false;
    }

    await startSudoKeepalive(environment: environment);
    return true;
  }

  static Future<void> startSudoKeepalive({
    Map<String, String>? environment,
  }) async {
    if (currentPlatform != AppPlatform.mac) return;

    await stopSudoKeepalive();

    final env = environment ?? await MoleCliLocator.macProcessEnvironment();
    final keepalive = await io.Process.start(
      '/bin/sh',
      [
        '-c',
        'sleep 2; while sudo -n -v 2>/dev/null; do sleep 30; done',
      ],
      environment: env,
    );
    _sudoKeepaliveProcess = keepalive;
    unawaited(keepalive.exitCode.then((_) {
      if (identical(_sudoKeepaliveProcess, keepalive)) {
        _sudoKeepaliveProcess = null;
      }
    }));
  }

  static Future<void> stopSudoKeepalive() async {
    final process = _sudoKeepaliveProcess;
    _sudoKeepaliveProcess = null;
    if (process == null) return;
    process.kill();
    await process.exitCode.catchError((_) => -1);
  }

  /// Caches sudo credentials before `mo` runs. `sudo` reads from `/dev/tty`,
  /// which the GUI app cannot write to, so authentication must happen first.
  static Future<bool> ensureMacSudoCredentials({
    required MolePasswordPromptCallback onPasswordPrompt,
    required String message,
  }) async {
    if (await prepareForMoleCli()) return true;

    var isRetry = false;
    while (true) {
      final password = await onPasswordPrompt(
        MolePasswordPrompt(
          message: message,
          isRetry: isRetry,
          errorMessage: isRetry ? 'Incorrect password.' : null,
        ),
      );

      if (password == null || password.isEmpty) return false;
      if (await authenticateSudo(password)) return true;
      isRetry = true;
    }
  }

  static String? parseCleanResultMessage(String output) {
    final summary = <String>[];
    for (final line in output.split('\n')) {
      final trimmed = normalizeCliLine(line);
      if (trimmed.isEmpty || trimmed.startsWith('===')) continue;
      if (trimmed.contains('Cleanup complete') ||
          trimmed.contains('Space freed:') ||
          trimmed.contains('Free space now:') ||
          trimmed.contains('System is already clean') ||
          trimmed.contains('Free space on')) {
        summary.add(trimmed);
      }
    }
    return summary.isEmpty ? null : summary.join('\n');
  }

  static String? parseOptimizeResultMessage(String output) {
    final summary = <String>[];
    for (final line in output.split('\n')) {
      final trimmed = normalizeCliLine(line);
      if (trimmed.isEmpty || trimmed.startsWith('===')) continue;
      if (trimmed.contains('Optimization Complete') ||
          trimmed.contains('Optimize complete') ||
          trimmed.contains('Dry Run Complete') ||
          (trimmed.contains('Applied') && trimmed.contains('optimizations')) ||
          trimmed.contains('System fully optimized') ||
          trimmed.contains('Optimizations applied:') ||
          trimmed.contains('System health:') ||
          (trimmed.contains('Would apply') && trimmed.contains('optimizations'))) {
        summary.add(trimmed);
      }
    }
    return summary.isEmpty ? null : summary.join('\n');
  }

  /// Printed before mole requests sudo during optimize.
  static bool isOptimizeAdminRequired(String line) {
    final normalized = normalizeCliLine(line);
    return normalized.contains('System optimization requires admin access') ||
        normalized.contains('Skipping sudo-required optimizations');
  }

  static String? parseUninstallResultMessage(String output) {
    final summary = <String>[];
    for (final line in output.split('\n')) {
      final trimmed = normalizeCliLine(line);
      if (trimmed.isEmpty || trimmed.startsWith('===')) continue;
      if (trimmed.contains('Uninstall complete') ||
          (trimmed.contains('Removed') && trimmed.contains('freed')) ||
          trimmed.contains('Background items') ||
          trimmed.contains('Login Items') ||
          trimmed.contains('Open System Settings')) {
        summary.add(trimmed);
      }
    }
    return summary.isEmpty ? null : summary.join('\n');
  }
}
