import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/models/analyze_snapshot.dart';
import 'package:mole_ui/core/platform/platform_shell.dart';
import 'package:mole_ui/core/services/analyze_service.dart';

class AnalyzeController extends ChangeNotifier {
  AnalyzeController({AnalyzeService? service})
      : _service = service ?? AnalyzeService();

  final AnalyzeService _service;

  String? _currentPath;
  AnalyzeSnapshot? _snapshot;
  int? _freeBytes;
  bool _isLoading = false;
  String? _errorMessage;

  AnalyzeSnapshot? get snapshot => _snapshot;
  int? get freeBytes => _freeBytes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canGoBack => _currentPath != null;

  String get currentPath => _snapshot?.path ?? _defaultRootPath;

  String get _defaultRootPath => PlatformShell.analyzeRootLabel == 'This PC'
      ? r'C:\'
      : '/';

  String get revealLabel => PlatformShell.revealInExplorerLabel;

  List<String> get breadcrumbSegments {
    final path = currentPath;
    final root = PlatformShell.analyzeRootLabel;

    if (path == '/' || path == r'C:\' || path == r'C:') {
      return [root];
    }

    final segments = <String>[root];
    segments.addAll(PlatformShell.pathSegments(path));
    return segments;
  }

  Future<void> loadInitial() async {
    if (_snapshot != null || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _freeBytes ??= await _service.fetchFreeBytes();
      _snapshot = await _service.analyzePath(_currentPath);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openEntry(AnalyzeEntry entry) async {
    if (!entry.isDir || _isLoading) return;
    _currentPath = entry.path;
    await refresh();
  }

  Future<void> goBack() async {
    if (_currentPath == null || _isLoading) return;
    _currentPath = PlatformShell.parentPath(_currentPath!);
    await refresh();
  }

  Future<void> navigateToBreadcrumb(int index) async {
    if (index < 0 || _isLoading) return;

    if (index == 0) {
      _currentPath = null;
    } else {
      _currentPath = PlatformShell.breadcrumbPath(breadcrumbSegments, index);
    }
    await refresh();
  }

  Future<void> openInFinder([String? path]) async {
    final target = path ?? currentPath;
    if (target.isEmpty) return;
    await _service.openInFinder(target);
  }
}
