import 'dart:convert';

import 'package:mole_ui/core/models/system_status.dart';
import 'package:mole_ui/core/platform/cli_commands.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class StatusService {
  StatusService({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  Future<SystemStatus> fetchStatus() async {
    final result = await _cli.runCapture(
      statusCommandArgs(),
      logOutput: false,
    );

    if (!result.success) {
      throw Exception(
        result.stderr.trim().isNotEmpty
            ? result.stderr.trim()
            : 'Status failed (exit ${result.exitCode})',
      );
    }

    final jsonText = _extractJsonObject(result.stdout);
    final decoded = json.decode(jsonText) as Map<String, dynamic>;
    return SystemStatus.fromJson(decoded);
  }

  String _extractJsonObject(String output) {
    final start = output.indexOf('{');
    final end = output.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('Status response did not contain JSON.');
    }
    return output.substring(start, end + 1);
  }
}
