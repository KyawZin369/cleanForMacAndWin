import 'dart:io';

import 'package:mole_ui/core/services/mole_cli_locator.dart';

class MoleCliInstallService {
  /// Opens Terminal.app and runs the Homebrew install for the `mo` CLI.
  Future<void> openTerminalInstall() async {
    final command = MoleCliLocator.brewInstallCommand;
    final zshCommand =
        "$command; echo; echo 'Installation finished. Switch back to the Mole app.'";

    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'tell application "Terminal"',
      '-e',
      'activate',
      '-e',
      'do script "/bin/zsh -l -c \\"$zshCommand\\""',
      '-e',
      'end tell',
    ]);

    if (result.exitCode != 0) {
      final message = (result.stderr as String?)?.trim();
      throw Exception(
        message?.isNotEmpty == true
            ? message!
            : 'Could not open Terminal (exit ${result.exitCode}).',
      );
    }
  }
}
