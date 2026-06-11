import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/logic/cli_activity.dart';
import 'package:mole_ui/core/logic/password_prompt_state.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/clean_command_runner.dart';
import 'package:mole_ui/core/services/cli_activity_parser.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

/// Shared optimize logic used by Mac and Windows UIs.
class OptimizeController extends ChangeNotifier {
  OptimizeController({MoleCliRunner? cli})
      : _cli = cli ?? MoleCliRunner(),
        _activityParser = CliActivityParser(
          sectionCatalog: switch (currentPlatform) {
            AppPlatform.mac => CliSectionCatalog.optimize,
            AppPlatform.windows => CliSectionCatalog.windowsOptimize,
            AppPlatform.unsupported => const {},
          },
        );

  final MoleCliRunner _cli;
  final CliActivityParser _activityParser;

  bool _isOptimizing = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _resultMessage;
  PasswordPromptState? _passwordPrompt;
  Timer? _progressTimer;

  bool get isOptimizing => _isOptimizing;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).round();
  String? get errorMessage => _errorMessage;
  String? get resultMessage => _resultMessage;
  PasswordPromptState? get passwordPrompt => _passwordPrompt;
  List<ActivitySection> get activitySections => _activityParser.sections;
  String? get currentActivityLabel => _activityParser.currentActivityLabel;

  String get optimizeCommandLabel => switch (currentPlatform) {
        AppPlatform.mac => 'mo optimize',
        AppPlatform.windows => 'winmole optimize',
        AppPlatform.unsupported => 'optimize',
      };

  Future<void> startOptimizing() async {
    if (_isOptimizing) return;

    if (currentPlatform == AppPlatform.unsupported) {
      _errorMessage = 'Optimize is only supported on macOS and Windows.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _resultMessage = null;
    _activityParser.reset();
    notifyListeners();

    if (currentPlatform == AppPlatform.mac) {
      final authed = await _ensureMacSudoForOptimize();
      if (!authed) return;
    }

    _isOptimizing = true;
    _progress = 0;
    notifyListeners();

    _startIndeterminateProgress();

    try {
      final result = await _cli.runStreaming(
        ['optimize'],
        onOutput: _handleCommandOutput,
        onPasswordPrompt: _requestPassword,
        passwordPromptMessage:
            'Mole needs your Mac password to optimize protected system caches.',
      );

      _stopIndeterminateProgress();
      _activityParser.finish();

      if (!_isOptimizing) return;

      if (result.success) {
        _progress = 1.0;
        _errorMessage = null;
        _resultMessage = MoleCliPassword.parseOptimizeResultMessage(
              '${result.stdout}\n${result.stderr}',
            ) ??
            'Optimization complete.';
      } else {
        _progress = 0;
        _resultMessage = null;
        final output = '${result.stdout}\n${result.stderr}';
        if (output.contains('Enter your credentials') ||
            output.contains('System optimization requires admin access')) {
          _errorMessage =
              'Administrator access is required. Tap Optimize again to continue.';
        } else {
          final message = result.stderr.trim().isNotEmpty
              ? result.stderr.trim()
              : result.stdout.trim();
          _errorMessage = message.isNotEmpty
              ? message
              : 'Optimize failed (exit ${result.exitCode})';
        }
      }
    } on MoleCliNotFoundException catch (error) {
      _stopIndeterminateProgress();
      if (!_isOptimizing) return;
      _progress = 0;
      _resultMessage = null;
      _errorMessage = error.message;
    } catch (error) {
      _stopIndeterminateProgress();
      if (!_isOptimizing) return;
      _progress = 0;
      _resultMessage = null;
      _errorMessage = 'Failed to run $optimizeCommandLabel: $error';
    } finally {
      _isOptimizing = false;
      _passwordPrompt = null;
      notifyListeners();
    }
  }

  void cancelOptimizing() {
    if (!_isOptimizing) return;
    _cli.cancel();
    _passwordPrompt?.completer.complete(null);
    _passwordPrompt = null;
    _stopIndeterminateProgress();
    _isOptimizing = false;
    _progress = 0;
    _errorMessage = 'Optimize cancelled.';
    _resultMessage = null;
    notifyListeners();
  }

  Future<bool> _ensureMacSudoForOptimize() async {
    const message =
        'Mole needs your Mac password to optimize protected system caches.';

    final authed = await MoleCliPassword.ensureMacSudoCredentials(
      onPasswordPrompt: _requestPassword,
      message: message,
    );
    _passwordPrompt = null;
    notifyListeners();
    if (!authed) {
      _errorMessage =
          'Administrator password is required to optimize system caches.';
      notifyListeners();
      return false;
    }

    if (!await MoleCliPassword.prepareForMoleCli()) {
      _errorMessage =
          'Could not verify administrator access. Try Optimize again.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<String?> _requestPassword(MolePasswordPrompt prompt) {
    final completer = Completer<String?>();
    _passwordPrompt = PasswordPromptState(
      message: prompt.message,
      isRetry: prompt.isRetry,
      errorMessage: prompt.errorMessage,
      completer: completer,
    );
    notifyListeners();
    return completer.future;
  }

  void _handleCommandOutput(String line) {
    _activityParser.handleLine(line);

    final parsed = parseProgressFromOutput(line);
    if (parsed != null) {
      _progress = parsed;
    } else if (_activityParser.sections.isNotEmpty) {
      _progress = _activityParser.progress;
    }

    notifyListeners();
  }

  void _startIndeterminateProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_isOptimizing) return;
      if (_activityParser.sections.isNotEmpty) {
        _progress = _activityParser.progress;
      } else if (_progress < 0.12) {
        _progress += 0.01;
      }
      notifyListeners();
    });
  }

  void _stopIndeterminateProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _stopIndeterminateProgress();
    _passwordPrompt?.completer.complete(null);
    _cli.cancel();
    unawaited(MoleCliPassword.stopSudoKeepalive());
    super.dispose();
  }
}
