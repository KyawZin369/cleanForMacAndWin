import 'dart:async';

import 'package:mole_ui/core/platform/cli_commands.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class CleanCommandResult {
  const CleanCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
  String? get errorMessage {
    if (success) return null;
    final message = stderr.trim().isNotEmpty ? stderr.trim() : stdout.trim();
    return message.isNotEmpty ? message : 'Clean command failed (exit $exitCode)';
  }

  String? get resultMessage {
    if (!success) return null;
    return MoleCliPassword.parseCleanResultMessage('$stdout\n$stderr');
  }
}

class CleanCommandRunner {
  CleanCommandRunner({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  bool get isRunning => _cli.isRunning;

  Future<CleanCommandResult> run({
    required void Function(String line) onOutput,
    MolePasswordPromptCallback? onPasswordPrompt,
  }) async {
    final result = isWindows
        ? await _cli.runKhineScriptStreaming(
            'bin/khine/clean_run.ps1',
            const [],
            onOutput: onOutput,
            onPasswordPrompt: onPasswordPrompt,
          )
        : await _cli.runStreaming(
            cleanCommandArgs(),
            onOutput: onOutput,
            onPasswordPrompt: onPasswordPrompt,
          );

    return CleanCommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }

  void cancel() => _cli.cancel();
}

/// Parses CLI output for progress values like `42%` or `progress: 42`.
double? parseProgressFromOutput(String line) {
  final percentMatch = RegExp(r'(\d{1,3})%').firstMatch(line);
  if (percentMatch != null) {
    final value = int.tryParse(percentMatch.group(1)!);
    if (value != null) {
      return (value / 100).clamp(0.0, 1.0);
    }
  }

  final progressMatch = RegExp(
    r'progress[:\s]+(\d{1,3})',
    caseSensitive: false,
  ).firstMatch(line);
  if (progressMatch != null) {
    final value = int.tryParse(progressMatch.group(1)!);
    if (value != null) {
      return (value / 100).clamp(0.0, 1.0);
    }
  }

  return null;
}
