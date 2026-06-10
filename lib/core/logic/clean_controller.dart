import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/logic/password_prompt_state.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/clean_command_runner.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';

/// Shared clean logic used by Mac and Windows UIs.
class CleanController extends ChangeNotifier {
  CleanController({CleanCommandRunner? commandRunner})
      : _commandRunner = commandRunner ?? CleanCommandRunner();

  final CleanCommandRunner _commandRunner;

  bool _isCleaning = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _resultMessage;
  PasswordPromptState? _passwordPrompt;
  Timer? _progressTimer;

  bool get isCleaning => _isCleaning;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).round();
  String? get errorMessage => _errorMessage;
  String? get resultMessage => _resultMessage;
  PasswordPromptState? get passwordPrompt => _passwordPrompt;

  String get cleanCommandLabel => switch (currentPlatform) {
        AppPlatform.mac => 'mo clean',
        AppPlatform.windows => 'winmole clean',
        AppPlatform.unsupported => 'clean',
      };

  Future<void> startCleaning() async {
    if (_isCleaning) return;

    if (currentPlatform == AppPlatform.unsupported) {
      _errorMessage = 'Clean is only supported on macOS and Windows.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _resultMessage = null;
    notifyListeners();

    if (currentPlatform == AppPlatform.mac) {
      final authed = await MoleCliPassword.ensureMacSudoCredentials(
        onPasswordPrompt: _requestPassword,
        message:
            'Mole needs your Mac password to clean protected system caches.',
      );
      _passwordPrompt = null;
      notifyListeners();
      if (!authed) {
        _errorMessage =
            'Administrator password is required to clean protected caches.';
        notifyListeners();
        return;
      }
    }

    _isCleaning = true;
    _progress = 0;
    notifyListeners();

    _startIndeterminateProgress();

    try {
      final result = await _commandRunner.run(
        onOutput: _handleCommandOutput,
        onPasswordPrompt: _requestPassword,
      );

      _stopIndeterminateProgress();

      if (!_isCleaning) return;

      if (result.success) {
        _progress = 1.0;
        _errorMessage = null;
        _resultMessage =
            result.resultMessage ?? 'Cleanup complete.';
      } else {
        _progress = 0;
        _resultMessage = null;
        _errorMessage = result.errorMessage;
      }
    } on MoleCliNotFoundException catch (error) {
      _stopIndeterminateProgress();
      if (!_isCleaning) return;
      _progress = 0;
      _resultMessage = null;
      _errorMessage = error.message;
    } catch (error) {
      _stopIndeterminateProgress();
      if (!_isCleaning) return;
      _progress = 0;
      _resultMessage = null;
      _errorMessage = 'Failed to run $cleanCommandLabel: $error';
    } finally {
      _isCleaning = false;
      _passwordPrompt = null;
      notifyListeners();
    }
  }

  void cancelCleaning() {
    if (!_isCleaning) return;
    _commandRunner.cancel();
    _passwordPrompt?.completer.complete(null);
    _passwordPrompt = null;
    _stopIndeterminateProgress();
    _isCleaning = false;
    _progress = 0;
    _errorMessage = 'Clean cancelled.';
    _resultMessage = null;
    notifyListeners();
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
    final parsed = parseProgressFromOutput(line);
    if (parsed != null) {
      _progress = parsed;
      notifyListeners();
    }
  }

  void _startIndeterminateProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_isCleaning) return;
      if (_progress < 0.9) {
        _progress += 0.01;
        notifyListeners();
      }
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
    _commandRunner.cancel();
    super.dispose();
  }
}
