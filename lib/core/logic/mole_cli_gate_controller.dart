import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/services/mole_cli_install_service.dart';
import 'package:mole_ui/core/services/mole_cli_locator.dart';

enum MoleCliGatePhase {
  checking,
  needsInstall,
  waitingForInstall,
  ready,
}

class MoleCliGateController extends ChangeNotifier {
  MoleCliGateController({MoleCliInstallService? installService})
      : _installService = installService ?? MoleCliInstallService();

  final MoleCliInstallService _installService;

  static const _pollInterval = Duration(seconds: 2);

  MoleCliGatePhase _phase = MoleCliGatePhase.checking;
  bool _bundledRuntimeAvailable = false;
  bool _homebrewInstalled = false;
  String? _errorMessage;
  bool _pollActive = false;

  MoleCliGatePhase get phase => _phase;
  bool get bundledRuntimeAvailable => _bundledRuntimeAvailable;
  bool get homebrewInstalled => _homebrewInstalled;
  String? get errorMessage => _errorMessage;
  bool get isReady => _phase == MoleCliGatePhase.ready;

  String get brewInstallCommand => MoleCliLocator.brewInstallCommand;

  Future<void> check() async {
    _errorMessage = null;
    _phase = MoleCliGatePhase.checking;
    notifyListeners();

    _bundledRuntimeAvailable = await MoleCliLocator.isBundledRuntimeAvailable();
    _homebrewInstalled = await MoleCliLocator.isHomebrewInstalled();
    final moPath = await MoleCliLocator.tryResolveExecutable();

    if (moPath != null && moPath.isNotEmpty) {
      _phase = MoleCliGatePhase.ready;
      notifyListeners();
      return;
    }

    MoleCliLocator.clearCache();
    _phase = MoleCliGatePhase.needsInstall;
    notifyListeners();
  }

  Future<void> installInTerminal() async {
    if (_phase == MoleCliGatePhase.waitingForInstall) return;

    _errorMessage = null;
    try {
      await _installService.openTerminalInstall();
      _phase = MoleCliGatePhase.waitingForInstall;
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

    while (_phase == MoleCliGatePhase.waitingForInstall) {
      await Future.delayed(_pollInterval);
      if (_phase != MoleCliGatePhase.waitingForInstall) break;

      MoleCliLocator.clearCache();
      final moPath = await MoleCliLocator.tryResolveExecutable();
      if (moPath != null && moPath.isNotEmpty) {
        _phase = MoleCliGatePhase.ready;
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
