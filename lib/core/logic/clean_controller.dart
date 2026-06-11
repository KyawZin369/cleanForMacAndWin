import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/logic/cli_activity.dart';
import 'package:mole_ui/core/logic/password_prompt_state.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/clean_command_runner.dart';
import 'package:mole_ui/core/services/cli_activity_parser.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';

/// Shared clean logic used by Mac and Windows UIs.
class CleanController extends ChangeNotifier {
  CleanController({CleanCommandRunner? commandRunner})
      : _commandRunner = commandRunner ?? CleanCommandRunner(),
        _activityParser = CliActivityParser(
          sectionCatalog: switch (currentPlatform) {
            AppPlatform.mac => CliSectionCatalog.macClean,
            AppPlatform.windows => CliSectionCatalog.windowsClean,
            AppPlatform.unsupported => const {},
          },
        );

  final CleanCommandRunner _commandRunner;
  final CliActivityParser _activityParser;

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
  List<ActivitySection> get activitySections => _activityParser.sections;
  String? get currentActivityLabel => _activityParser.currentActivityLabel;

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
    _activityParser.reset();
    notifyListeners();

    if (currentPlatform == AppPlatform.mac) {
      final authed = await _ensureMacSudoForClean();
      if (!authed) return;
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
      _activityParser.finish();

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

  Future<bool> _ensureMacSudoForClean() async {
    const message =
        'Mole needs your Mac password to clean protected system caches.';

    final authed = await MoleCliPassword.ensureMacSudoCredentials(
      onPasswordPrompt: _requestPassword,
      message: message,
    );
    _passwordPrompt = null;
    notifyListeners();
    if (!authed) {
      _errorMessage =
          'Administrator password is required to clean protected caches.';
      notifyListeners();
      return false;
    }

    if (!await MoleCliPassword.prepareForMoleCli()) {
      _errorMessage =
          'Could not verify administrator access. Try Clean again.';
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
      if (!_isCleaning) return;
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
    _commandRunner.cancel();
    unawaited(MoleCliPassword.stopSudoKeepalive());
    super.dispose();
  }
}
