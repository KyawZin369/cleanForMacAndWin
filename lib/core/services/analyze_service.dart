import 'dart:convert';

import 'package:mole_ui/core/models/analyze_snapshot.dart';
import 'package:mole_ui/core/platform/cli_commands.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/platform/platform_shell.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class AnalyzeService {
  AnalyzeService({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  Future<AnalyzeSnapshot> analyzePath([String? path]) async {
    final result = isWindows
        ? await _cli.runKhineScriptCapture(
            'bin/khine/analyze_json.ps1',
            path != null && path.isNotEmpty ? ['-Path', path] : const [],
            logOutput: false,
          )
        : await _cli.runCapture(
            analyzeCommandArgs(path),
            logOutput: false,
          );
    if (!result.success) {
      throw Exception(
        result.stderr.trim().isNotEmpty
            ? result.stderr.trim()
            : 'Analyze failed (exit ${result.exitCode})',
      );
    }

    final jsonText = _extractJsonObject(result.stdout);
    final decoded = json.decode(jsonText) as Map<String, dynamic>;
    return AnalyzeSnapshot.fromJson(decoded);
  }

  Future<int?> fetchFreeBytes() => PlatformShell.fetchFreeBytes();

  Future<void> openInFinder(String path) => PlatformShell.revealInFileManager(path);

  String _extractJsonObject(String output) {
    final start = output.indexOf('{');
    final end = output.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('Analyze response did not contain JSON.');
    }
    return output.substring(start, end + 1);
  }
}
