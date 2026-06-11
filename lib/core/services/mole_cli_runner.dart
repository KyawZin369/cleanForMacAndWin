import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:mole_ui/core/services/mole_cli_locator.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';

class MoleCliResult {
  const MoleCliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
}

class MoleCliRunner {
  io.Process? _activeProcess;

  bool get isRunning => _activeProcess != null;

  Future<MoleCliResult> runKhineScriptCapture(
    String scriptRelative,
    List<String> args, {
    bool logOutput = true,
  }) async {
    final launch = await MoleCliLocator.buildKhineScriptLaunchSpec(
      scriptRelative,
      args,
    );
    return _runCaptureLaunch(launch, logOutput: logOutput);
  }

  Future<MoleCliResult> runCapture(
    List<String> args, {
    bool logOutput = true,
  }) async {
    final launch = await MoleCliLocator.buildLaunchSpec(args);
    return _runCaptureLaunch(launch, logOutput: logOutput);
  }

  Future<MoleCliResult> _runCaptureLaunch(
    CliLaunchSpec launch, {
    required bool logOutput,
  }) async {
    _logCommand(launch.executable, launch.args);

    final result = await io.Process.run(
      launch.executable,
      launch.args,
      environment: launch.environment,
      workingDirectory: launch.workingDirectory,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
      runInShell: launch.runInShell,
    );

    final stdoutText = result.stdout as String? ?? '';
    final stderrText = result.stderr as String? ?? '';
    if (logOutput) {
      _logCapturedOutput(stdoutText, isStderr: false);
      _logCapturedOutput(stderrText, isStderr: true);
    } else {
      _logSummary(stdoutText, stderrText);
    }
    _logExit(result.exitCode);

    return MoleCliResult(
      exitCode: result.exitCode,
      stdout: stdoutText,
      stderr: stderrText,
    );
  }

  Future<MoleCliResult> runStreaming(
    List<String> args, {
    void Function(String line)? onOutput,
    MolePasswordPromptCallback? onPasswordPrompt,
    bool autoConfirmUninstall = false,
    String passwordPromptMessage =
        'Mole needs your Mac password to clean protected system caches.',
  }) async {
    if (_activeProcess != null) {
      throw StateError('A Mole CLI command is already running.');
    }

    final launch = await MoleCliLocator.buildLaunchSpec(args);
    _logCommand(launch.executable, launch.args);

    final process = await io.Process.start(
      launch.executable,
      launch.args,
      environment: launch.environment,
      workingDirectory: launch.workingDirectory,
      runInShell: launch.runInShell,
    );
    _activeProcess = process;

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    var passwordPromptOpen = false;
    var wrongPassword = false;
    var uninstallProceedConfirmed = false;
    var uninstallExecuteConfirmed = false;
    var uninstallExecuteScheduled = false;

    Future<void> sendUninstallProceed() async {
      if (!autoConfirmUninstall || uninstallProceedConfirmed) return;
      uninstallProceedConfirmed = true;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        process.stdin.writeln('y');
        await process.stdin.flush();
      } catch (_) {
        uninstallProceedConfirmed = false;
      }
    }

    Future<void> sendUninstallExecute() async {
      if (!autoConfirmUninstall || uninstallExecuteConfirmed) return;
      uninstallExecuteConfirmed = true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        process.stdin.writeln('');
        await process.stdin.flush();
      } catch (_) {
        uninstallExecuteConfirmed = false;
      }
    }

    void scheduleUninstallExecute() {
      if (!autoConfirmUninstall || uninstallExecuteScheduled) return;
      uninstallExecuteScheduled = true;
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!uninstallExecuteConfirmed) {
          unawaited(sendUninstallExecute());
        }
      });
    }

    Future<void> handlePasswordPrompt({bool proactive = false}) async {
      if (passwordPromptOpen || onPasswordPrompt == null) return;
      if (proactive && await MoleCliPassword.hasActiveSudoSession()) return;

      passwordPromptOpen = true;

      try {
        while (true) {
          final password = await onPasswordPrompt(
            MolePasswordPrompt(
              message: passwordPromptMessage,
              isRetry: wrongPassword,
              errorMessage: wrongPassword ? 'Incorrect password.' : null,
            ),
          );

          if (password == null || password.isEmpty) {
            process.kill();
            return;
          }

          final authed = await MoleCliPassword.authenticateSudo(password);
          if (authed) {
            wrongPassword = false;
            return;
          }

          wrongPassword = true;
        }
      } finally {
        passwordPromptOpen = false;
      }
    }

    void handleLine(String line, StringBuffer buffer, {required bool isStderr}) {
      buffer.writeln(line);
      _logLine(line, isStderr: isStderr);
      onOutput?.call(line);

      if (autoConfirmUninstall) {
        if (MoleCliPassword.isUninstallProceedPoint(line)) {
          unawaited(sendUninstallProceed());
        } else if (MoleCliPassword.isUninstallPreviewStart(line)) {
          scheduleUninstallExecute();
        } else if (MoleCliPassword.isUninstallExecutePoint(line)) {
          unawaited(sendUninstallExecute());
        }
      }

      if (MoleCliPassword.isWrongPasswordLine(line)) {
        wrongPassword = true;
      }
      if (MoleCliPassword.isPasswordPromptLine(line)) {
        unawaited(handlePasswordPrompt());
      } else if (MoleCliPassword.isUninstallAdminRequired(line) ||
          MoleCliPassword.isOptimizeAdminRequired(line)) {
        unawaited(handlePasswordPrompt(proactive: true));
      } else if (MoleCliPassword.isSudoSectionHeader(line)) {
        unawaited(handlePasswordPrompt(proactive: true));
      }
    }

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => handleLine(line, stdoutBuffer, isStderr: false));

    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => handleLine(line, stderrBuffer, isStderr: true));

    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();
    _activeProcess = null;
    _logExit(exitCode);

    return MoleCliResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  void cancel() {
    final process = _activeProcess;
    if (process == null) return;
    process.kill();
    _activeProcess = null;
  }

  void _logCommand(String executable, List<String> args) {
    io.stdout.writeln('[mole_ui] > $executable ${args.join(' ')}');
  }

  void _logLine(String line, {required bool isStderr}) {
    final sink = isStderr ? io.stderr : io.stdout;
    sink.writeln('[mole_ui] $line');
  }

  void _logCapturedOutput(String text, {required bool isStderr}) {
    for (final line in const LineSplitter().convert(text)) {
      if (line.isEmpty) continue;
      _logLine(line, isStderr: isStderr);
    }
  }

  void _logExit(int exitCode) {
    io.stdout.writeln('[mole_ui] < exit $exitCode');
  }

  void _logSummary(String stdoutText, String stderrText) {
    final stdoutLines = stdoutText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .length;
    final stderrLines = stderrText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .length;
    if (stdoutLines > 0) {
      io.stdout.writeln('[mole_ui] ($stdoutLines stdout lines captured)');
    }
    if (stderrLines > 0) {
      io.stderr.writeln('[mole_ui] ($stderrLines stderr lines captured)');
    }
  }
}
