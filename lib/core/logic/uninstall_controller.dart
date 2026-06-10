import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/logic/password_prompt_state.dart';
import 'package:mole_ui/core/models/uninstall_app.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';
import 'package:mole_ui/core/services/uninstall_service.dart';

enum UninstallSort {
  nameAsc,
  nameDesc,
  sizeDesc,
  sizeAsc,
  sourceAsc,
}

class UninstallController extends ChangeNotifier {
  UninstallController({UninstallService? service})
      : _service = service ?? UninstallService();

  final UninstallService _service;
  static const _listCacheTtl = Duration(minutes: 5);

  List<UninstallApp> _apps = [];
  DateTime? _appsLoadedAt;
  final Set<String> _selected = {};
  String _searchQuery = '';
  UninstallSort _sort = UninstallSort.nameAsc;
  bool _isLoading = false;
  bool _isUninstalling = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _resultMessage;
  PasswordPromptState? _passwordPrompt;

  List<UninstallApp> get apps => _apps;
  Set<String> get selectedUninstallNames => Set.unmodifiable(_selected);
  int get selectedCount => _selected.length;
  String get searchQuery => _searchQuery;
  UninstallSort get sort => _sort;
  bool get isLoading => _isLoading;
  bool get isUninstalling => _isUninstalling;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String? get resultMessage => _resultMessage;
  PasswordPromptState? get passwordPrompt => _passwordPrompt;

  List<UninstallApp> get visibleApps {
    final query = _searchQuery.trim().toLowerCase();
    var items = _apps;
    if (query.isNotEmpty) {
      items = items
          .where(
            (app) =>
                app.name.toLowerCase().contains(query) ||
                app.source.toLowerCase().contains(query) ||
                app.uninstallName.toLowerCase().contains(query),
          )
          .toList();
    }

    items = [...items];
    items.sort(_compareApps);
    return items;
  }

  Future<void> loadApps({bool force = false}) async {
    if (_isLoading || (!force && _isUninstalling)) return;

    if (!force &&
        _apps.isNotEmpty &&
        _appsLoadedAt != null &&
        DateTime.now().difference(_appsLoadedAt!) < _listCacheTtl) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _statusMessage = 'Loading installed apps...';
    notifyListeners();

    try {
      _apps = await _service.fetchApps();
      _appsLoadedAt = DateTime.now();
      _selected.removeWhere(
        (name) => !_apps.any((app) => app.uninstallName == name),
      );
      _statusMessage = null;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      _statusMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(UninstallSort sort) {
    _sort = sort;
    notifyListeners();
  }

  bool isSelected(UninstallApp app) => _selected.contains(app.uninstallName);

  void toggleSelection(UninstallApp app) {
    if (_isUninstalling) return;
    if (_selected.contains(app.uninstallName)) {
      _selected.remove(app.uninstallName);
    } else {
      _selected.add(app.uninstallName);
    }
    notifyListeners();
  }

  void selectAllVisible() {
    if (_isUninstalling) return;
    for (final app in visibleApps) {
      _selected.add(app.uninstallName);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_isUninstalling) return;
    _selected.clear();
    notifyListeners();
  }

  Future<bool> uninstallSelected() async {
    if (_isUninstalling || _selected.isEmpty) return false;

    _errorMessage = null;
    _resultMessage = null;
    notifyListeners();

    if (currentPlatform == AppPlatform.mac) {
      final authed = await MoleCliPassword.ensureMacSudoCredentials(
        onPasswordPrompt: _requestPassword,
        message:
            'Mole needs your Mac password to uninstall protected system apps.',
      );
      _passwordPrompt = null;
      notifyListeners();
      if (!authed) {
        _errorMessage =
            'Administrator password is required to uninstall protected apps.';
        notifyListeners();
        return false;
      }
    }

    _isUninstalling = true;
    _statusMessage = 'Removing ${_selected.length} app(s)...';
    notifyListeners();

    final targets = _selected.toList();
    String? latestStatus;
    try {
      final result = await _service.uninstallApps(
        targets,
        onOutput: (line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return;
          latestStatus = trimmed;
          _statusMessage = trimmed;
          notifyListeners();
        },
        onPasswordPrompt: _requestPassword,
      );

      if (!result.success) {
        _errorMessage = result.stderr.trim().isNotEmpty
            ? result.stderr.trim()
            : 'Uninstall failed (exit ${result.exitCode})';
        return false;
      }

      _selected.clear();
      _apps.removeWhere((app) => targets.contains(app.uninstallName));
      _statusMessage = null;
      _resultMessage = MoleCliPassword.parseUninstallResultMessage(
            '${result.stdout}\n${result.stderr}',
          ) ??
          latestStatus ??
          'Uninstall complete.';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isUninstalling = false;
      _passwordPrompt = null;
      notifyListeners();
    }
  }

  Future<String?> _requestPassword(MolePasswordPrompt prompt) {
    final completer = Completer<String?>();
    _passwordPrompt = PasswordPromptState(
      message: prompt.message,
      isRetry: prompt.isRetry,
      errorMessage: prompt.errorMessage,
      completer: completer,
    );
    notifyListeners();
    return completer.future;
  }

  int _compareApps(UninstallApp a, UninstallApp b) {
    return switch (_sort) {
      UninstallSort.nameAsc => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      UninstallSort.nameDesc => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      UninstallSort.sizeDesc =>
        sizeToBytes(b.size).compareTo(sizeToBytes(a.size)),
      UninstallSort.sizeAsc =>
        sizeToBytes(a.size).compareTo(sizeToBytes(b.size)),
      UninstallSort.sourceAsc =>
        a.source.toLowerCase().compareTo(b.source.toLowerCase()),
    };
  }

  @override
  void dispose() {
    _passwordPrompt?.completer.complete(null);
    super.dispose();
  }
}
