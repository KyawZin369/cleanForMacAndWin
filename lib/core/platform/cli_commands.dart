import 'package:mole_ui/core/platform/platform_info.dart';

/// Platform-specific CLI argument lists for shared services.
List<String> cleanCommandArgs() {
  if (isWindows) {
    return const ['clean', '-All'];
  }
  return const ['clean'];
}

List<String> uninstallListArgs() {
  if (isWindows) {
    return const ['uninstall', '--list'];
  }
  return const ['uninstall', '--list'];
}

List<String> uninstallAppsArgs(List<String> uninstallNames) {
  if (isWindows) {
    return ['uninstall', ...uninstallNames];
  }
  return ['uninstall', ...uninstallNames];
}

List<String> analyzeCommandArgs([String? path]) {
  if (isWindows) {
    final args = <String>[];
    if (path != null && path.isNotEmpty) {
      args.addAll(['-Path', path]);
    }
    return args;
  }

  final args = <String>['analyze', '-json'];
  if (path != null && path.isNotEmpty) {
    args.add(path);
  }
  return args;
}

List<String> statusCommandArgs() {
  if (isWindows) {
    return const [];
  }
  return const ['status', '-json'];
}

String? windowsKhineScriptForAnalyze() {
  if (!isWindows) return null;
  return 'bin/khine/analyze_json.ps1';
}

String? windowsKhineScriptForStatus() {
  if (!isWindows) return null;
  return 'bin/khine/status_json.ps1';
}
