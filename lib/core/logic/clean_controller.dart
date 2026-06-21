import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/logic/clean_confirm_prompt_state.dart';
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
  CleanConfirmPromptState? _confirmPrompt;
  Timer? _progressTimer;
  final List<String> _streamedErrors = [];
  final List<String> _streamedWarnings = [];
  bool _hasLockedFileFailures = false;
  bool _browserLockDetected = false;
  bool _nonBrowserLockDetected = false;
  final Set<String> _lockedBrowsers = {};
  bool _editorLockDetected = false;

  bool get isCleaning => _isCleaning;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).round();
  String? get errorMessage => _errorMessage;
  String? get resultMessage => _resultMessage;
  PasswordPromptState? get passwordPrompt => _passwordPrompt;
  CleanConfirmPromptState? get confirmPrompt => _confirmPrompt;
  List<ActivitySection> get activitySections => _activityParser.sections;
  String? get currentActivityLabel => _activityParser.currentActivityLabel;
  List<String> get cleanWarnings => List.unmodifiable(_streamedWarnings);

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
    _streamedErrors.clear();
    _streamedWarnings.clear();
    _hasLockedFileFailures = false;
    _browserLockDetected = false;
    _nonBrowserLockDetected = false;
    _lockedBrowsers.clear();
    _editorLockDetected = false;
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
      var result = await _commandRunner.run(
        onOutput: _handleCommandOutput,
        onPasswordPrompt: _requestPassword,
      );

      if (!_isCleaning) return;

      if (isWindows) {
        if (_browserLockDetected) {
          final runBrowserRetry = await _requestConfirm(
            title: 'Close your browser',
            message: _buildCloseBrowserMessage(),
            confirmLabel: 'I closed my browser — retry',
            cancelLabel: 'Skip browser cleanup',
          );
          _clearConfirmPrompt();
          if (runBrowserRetry == true) {
            final browserResult = await _commandRunner.runBrowserRetryPhase(
              onOutput: _handleCommandOutput,
            );
            result = _mergeCleanResults(result, browserResult);
          }
        }

        final adminResult = await _commandRunner.runAdminPhase(
          onOutput: _handleCommandOutput,
        );
        result = _mergeCleanResults(result, adminResult);

        if (_nonBrowserLockDetected) {
          final runRetry = await _requestConfirm(
            title: 'Close apps and retry',
            message: _buildCloseAppsMessage(),
            confirmLabel: 'I closed them — retry',
            cancelLabel: 'Skip retry',
          );
          _clearConfirmPrompt();
          if (runRetry == true) {
            final retryResult = await _commandRunner.runRetryLockedPhase(
              onOutput: _handleCommandOutput,
            );
            result = _mergeCleanResults(result, retryResult);
          }
        }
      }

      _stopIndeterminateProgress();
      _activityParser.finish();

      if (!_isCleaning) return;

      if (result.success || _isPartialCleanSuccess(result)) {
        _progress = 1.0;
        _errorMessage = null;
        _resultMessage = _buildCleanResultMessage(result);
      } else {
        _progress = 0;
        _resultMessage = null;
        _errorMessage = _resolveCleanErrorMessage(result);
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
      _confirmPrompt = null;
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

  Future<bool?> _requestConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    final completer = Completer<bool?>();
    _confirmPrompt = CleanConfirmPromptState(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      completer: completer,
    );
    notifyListeners();
    return completer.future;
  }

  CleanCommandResult _mergeCleanResults(
    CleanCommandResult first,
    CleanCommandResult second,
  ) {
    return CleanCommandResult(
      exitCode: first.success && second.success ? 0 : 1,
      stdout: '${first.stdout}\n${second.stdout}',
      stderr: '${first.stderr}\n${second.stderr}',
    );
  }

  void _clearConfirmPrompt() {
    _confirmPrompt = null;
    notifyListeners();
  }

  String _buildCloseBrowserMessage() {
    final browsers = _lockedBrowsers.toList()..sort();
    final browserList = browsers.isEmpty
        ? 'your browser (Chrome, Edge, Firefox, etc.)'
        : browsers.join(', ');

    return 'Some browser cache files could not be removed because $browserList is still running.\n\n'
        'Please close all browser windows completely, then click "I closed my browser — retry" to clean browser caches again.';
  }

  String _buildCloseAppsMessage() {
    final parts = <String>[];
    if (_editorLockDetected) {
      parts.add('code editors (VS Code, Cursor, etc.)');
    }

    final target = parts.isEmpty
        ? 'apps that may be locking temp or cache files (editors, games, GPU drivers)'
        : parts.join(' and ');

    return 'Some files could not be removed because they are in use.\n\n'
        'Please close $target, then click "I closed them — retry" to clean those files again.';
  }

  void _handleCommandOutput(String line) {
    _activityParser.handleLine(line);

    final parsed = parseProgressFromOutput(line);
    if (parsed != null) {
      _progress = parsed;
    } else if (_activityParser.sections.isNotEmpty) {
      _progress = _activityParser.progress;
    }

    final errorLine = _extractStreamedError(line);
    if (errorLine != null) {
      _streamedErrors.add(errorLine);
    }

    final warningLine = _extractStreamedWarning(line);
    if (warningLine != null && !_streamedWarnings.contains(warningLine)) {
      _streamedWarnings.add(warningLine);
    }

    notifyListeners();
  }

  String? _extractStreamedWarning(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower.contains('requires admin') && lower.contains('skipping')) {
      return trimmed;
    }
    if (lower.contains('could not be removed') ||
        lower.contains('more item(s) could not be removed') ||
        lower.contains('in use by another program') ||
        lower.contains('access to the path is denied')) {
      _hasLockedFileFailures = true;
      _trackLockedFileContext(lower);
      return trimmed;
    }

    if (RegExp(r'^[!?●⚠]\s+', unicode: true).hasMatch(trimmed) &&
        !lower.contains('nothing to tidy')) {
      return trimmed.replaceFirst(RegExp(r'^[!?●⚠]\s+', unicode: true), '').trim();
    }

    return null;
  }

  void _trackLockedFileContext(String lower) {
    final isBrowserLock = lower.contains('chrome') ||
        lower.contains('edge') ||
        lower.contains('firefox') ||
        lower.contains('brave') ||
        lower.contains('opera') ||
        lower.contains('browser') ||
        lower.contains('no_vary_search') ||
        lower.contains('code cache');

    if (isBrowserLock) {
      _browserLockDetected = true;
      if (lower.contains('edge')) {
        _lockedBrowsers.add('Microsoft Edge');
      }
      if (lower.contains('chrome')) {
        _lockedBrowsers.add('Google Chrome');
      }
      if (lower.contains('firefox')) {
        _lockedBrowsers.add('Mozilla Firefox');
      }
      if (lower.contains('brave')) {
        _lockedBrowsers.add('Brave');
      }
      if (lower.contains('opera')) {
        _lockedBrowsers.add('Opera');
      }
      return;
    }

    _nonBrowserLockDetected = true;
    if (lower.contains('vscode') ||
        lower.contains('vs code') ||
        lower.contains('cursor') ||
        lower.contains('.tmp') ||
        lower.contains('temp files')) {
      _editorLockDetected = true;
    }
    if (lower.contains('shader') ||
        lower.contains('nvidia') ||
        lower.contains('amd') ||
        lower.contains('.parc')) {
      _editorLockDetected = true;
    }
  }

  bool _isPartialCleanSuccess(CleanCommandResult result) {
    if (isWindows && result.exitCode == 1 && _activityParser.sections.isNotEmpty) {
      return true;
    }
    return _activityParser.sections.any(
      (section) =>
          section.status == ActivitySectionStatus.completed &&
          section.completedItemCount > 0,
    );
  }

  String _buildCleanResultMessage(CleanCommandResult result) {
    final base = result.resultMessage ?? 'Cleanup complete.';
    if (_streamedWarnings.isEmpty) {
      return base;
    }

    final warnings = _streamedWarnings.take(5).join('\n');
    final extra = _streamedWarnings.length > 5
        ? '\n...and ${_streamedWarnings.length - 5} more warnings.'
        : '';
    return '$base\n\nSome items could not be removed:\n$warnings$extra';
  }

  String? _extractStreamedError(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (RegExp(r'^x\s+', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed.replaceFirst(RegExp(r'^x\s+', caseSensitive: false), '').trim();
    }
    if (lower.contains('propertynotfoundexception') ||
        lower.contains('cannot be found on this object') ||
        lower.contains(' failed: ')) {
      return trimmed;
    }
    return null;
  }

  String? _resolveCleanErrorMessage(CleanCommandResult result) {
    if (_streamedErrors.isNotEmpty) {
      return _streamedErrors.join('\n');
    }
    return result.errorMessage;
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
