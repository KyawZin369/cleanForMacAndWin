import 'dart:convert';

import 'package:mole_ui/core/models/uninstall_app.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class UninstallService {
  UninstallService({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  Future<List<UninstallApp>> fetchApps() async {
    final result = await _cli.runCapture(
      ['uninstall', '--list'],
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

    return _cli.runStreaming(
      ['uninstall', ...uninstallNames],
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
