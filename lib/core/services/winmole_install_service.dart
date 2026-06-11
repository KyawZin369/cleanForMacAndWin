import 'dart:io';

import 'package:mole_ui/core/services/mole_cli_locator.dart';

class WinMoleInstallService {
  Future<void> openPowerShellInstall() async {
    final root = await MoleCliLocator.bundledMoleRoot();
    if (root == null) {
      throw StateError(
        'WinMole vendor files were not found. ${MoleCliLocator.installHint}',
      );
    }

    final installScript = '$root\\install.ps1';
    if (!await File(installScript).exists()) {
      throw StateError(
        'install.ps1 was not found in $root. ${MoleCliLocator.installHint}',
      );
    }

    await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process powershell -Verb RunAs -ArgumentList '
            '"-NoProfile -ExecutionPolicy Bypass -File '
            '$installScript -AddToPath"',
      ],
      runInShell: false,
    );
  }
}
