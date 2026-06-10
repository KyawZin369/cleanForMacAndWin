import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/models/analyze_snapshot.dart';
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

  String get currentPath => _snapshot?.path ?? '/';

  List<String> get breadcrumbSegments {
    final path = currentPath;
    if (path == '/') return ['Macintosh HD'];

    final segments = <String>['Macintosh HD'];
    segments.addAll(path.split('/').where((part) => part.isNotEmpty));
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
    _currentPath = _parentPath(_currentPath!);
    await refresh();
  }

  Future<void> navigateToBreadcrumb(int index) async {
    if (index < 0 || _isLoading) return;

    if (index == 0) {
      _currentPath = null;
    } else {
      final segments = breadcrumbSegments;
      if (index >= segments.length) return;
      _currentPath = '/${segments.sublist(1, index + 1).join('/')}';
    }
    await refresh();
  }

  Future<void> openInFinder([String? path]) async {
    final target = path ?? currentPath;
    if (target.isEmpty) return;
    await _service.openInFinder(target);
  }

  String? _parentPath(String path) {
    final normalized = path.replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty || normalized == '/') return null;

    final index = normalized.lastIndexOf('/');
    if (index <= 0) return null;
    return normalized.substring(0, index);
  }
}
