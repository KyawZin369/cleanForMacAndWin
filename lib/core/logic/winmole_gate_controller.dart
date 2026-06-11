import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';
import 'package:mole_ui/core/services/winmole_install_service.dart';

enum WinMoleGatePhase {
  checking,
  needsInstall,
  waitingForInstall,
  ready,
}

class WinMoleGateController extends ChangeNotifier {
  WinMoleGateController({WinMoleInstallService? installService})
      : _installService = installService ?? WinMoleInstallService();

  final WinMoleInstallService _installService;

  static const _pollInterval = Duration(seconds: 2);

  WinMoleGatePhase _phase = WinMoleGatePhase.checking;
  bool _bundledRuntimeAvailable = false;
  bool _winMoleOnPath = false;
  String? _errorMessage;
  bool _pollActive = false;

  WinMoleGatePhase get phase => _phase;
  bool get bundledRuntimeAvailable => _bundledRuntimeAvailable;
  bool get winMoleOnPath => _winMoleOnPath;
  String? get errorMessage => _errorMessage;
  bool get isReady => _phase == WinMoleGatePhase.ready;

  String get installCommand => MoleCliLocator.winMoleInstallCommand;

  Future<void> check() async {
    _errorMessage = null;
    _phase = WinMoleGatePhase.checking;
    notifyListeners();

    _bundledRuntimeAvailable = await MoleCliLocator.isBundledRuntimeAvailable();
    _winMoleOnPath = await MoleCliLocator.isWinMoleOnPath();
    final scriptPath = await MoleCliLocator.tryResolveExecutable();

    if (scriptPath != null && scriptPath.isNotEmpty) {
      _phase = WinMoleGatePhase.ready;
      notifyListeners();
      return;
    }

    MoleCliLocator.clearCache();
    _phase = WinMoleGatePhase.needsInstall;
    notifyListeners();
  }

  Future<void> installInPowerShell() async {
    if (_phase == WinMoleGatePhase.waitingForInstall) return;

    _errorMessage = null;
    try {
      await _installService.openPowerShellInstall();
      _phase = WinMoleGatePhase.waitingForInstall;
      notifyListeners();
      unawaited(_pollUntilInstalled());
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> _pollUntilInstalled() async {
    if (_pollActive) return;
    _pollActive = true;

    while (_phase == WinMoleGatePhase.waitingForInstall) {
      await Future.delayed(_pollInterval);
      if (_phase != WinMoleGatePhase.waitingForInstall) break;

      MoleCliLocator.clearCache();
      final scriptPath = await MoleCliLocator.tryResolveExecutable();
      if (scriptPath != null && scriptPath.isNotEmpty) {
        _phase = WinMoleGatePhase.ready;
        _errorMessage = null;
        _pollActive = false;
        notifyListeners();
        return;
      }
    }

    _pollActive = false;
  }

  @override
  void dispose() {
    _pollActive = false;
    super.dispose();
  }
}
