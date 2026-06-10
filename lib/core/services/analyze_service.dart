import 'dart:convert';
import 'dart:io' as io;

import 'package:mole_ui/core/models/analyze_snapshot.dart';
import 'package:mole_ui/core/services/mole_cli_runner.dart';

class AnalyzeService {
  AnalyzeService({MoleCliRunner? cli}) : _cli = cli ?? MoleCliRunner();

  final MoleCliRunner _cli;

  Future<AnalyzeSnapshot> analyzePath([String? path]) async {
    final args = <String>['analyze', '-json'];
    if (path != null && path.isNotEmpty) {
      args.add(path);
    }

    final result = await _cli.runCapture(args, logOutput: false);
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

  Future<int?> fetchFreeBytes() async {
    final result = await io.Process.run('df', ['-k', '/']);
    final lines = (result.stdout as String? ?? '').split('\n');
    if (lines.length < 2) return null;

    final parts = lines[1].trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return null;

    final availableKb = int.tryParse(parts[3]);
    return availableKb != null ? availableKb * 1024 : null;
  }

  Future<void> openInFinder(String path) async {
    await io.Process.run('open', [path]);
  }

  String _extractJsonObject(String output) {
    final start = output.indexOf('{');
    final end = output.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('Analyze response did not contain JSON.');
    }
    return output.substring(start, end + 1);
  }
}
