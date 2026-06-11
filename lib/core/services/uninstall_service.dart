import 'dart:convert';

import 'package:mole_ui/core/models/uninstall_app.dart';
import 'package:mole_ui/core/platform/cli_commands.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class UninstallService {
  UninstallService({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  Future<List<UninstallApp>> fetchApps() async {
    final result = isWindows
        ? await _cli.runKhineScriptCapture(
            'bin/khine/uninstall_list.ps1',
            const [],
            logOutput: false,
          )
        : await _cli.runCapture(
            uninstallListArgs(),
            logOutput: false,
          );
    if (!result.success) {
      throw Exception(
        result.stderr.trim().isNotEmpty
            ? result.stderr.trim()
            : 'Failed to load apps (exit ${result.exitCode})',
      );
    }

    final jsonText = _extractJsonArray(result.stdout);
    final decoded = json.decode(jsonText) as List<dynamic>;

    return decoded
        .map((item) => UninstallApp.fromJson(item as Map<String, dynamic>))
        .where((app) => app.uninstallName.isNotEmpty && app.name.isNotEmpty)
        .toList();
  }

  Future<MoleCliResult> uninstallApps(
    List<String> uninstallNames, {
    void Function(String line)? onOutput,
    MolePasswordPromptCallback? onPasswordPrompt,
  }) {
    if (uninstallNames.isEmpty) {
      throw ArgumentError('No apps selected for uninstall.');
    }

    if (isWindows) {
      return _cli.runKhineScriptStreaming(
        'bin/khine/uninstall_apps.ps1',
        uninstallNames,
        onOutput: onOutput,
        onPasswordPrompt: onPasswordPrompt,
      );
    }

    return _cli.runStreaming(
      uninstallAppsArgs(uninstallNames),
      onOutput: onOutput,
      onPasswordPrompt: onPasswordPrompt,
      autoConfirmUninstall: true,
    );
  }

  String _extractJsonArray(String output) {
    final start = output.indexOf('[');
    final end = output.lastIndexOf(']');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('App list response did not contain JSON.');
    }
    return output.substring(start, end + 1);
  }
}
