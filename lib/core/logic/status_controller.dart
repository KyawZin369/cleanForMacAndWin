import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mole_ui/core/models/system_status.dart';
import 'package:mole_ui/core/services/status_service.dart';

class StatusController extends ChangeNotifier {
  StatusController({StatusService? service})
      : _service = service ?? StatusService();

  final StatusService _service;

  static const _pollInterval = Duration(seconds: 4);

  SystemStatus? _status;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isMonitoring = false;
  bool _refreshInFlight = false;
  DateTime? _lastUpdated;

  SystemStatus? get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isMonitoring => _isMonitoring;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    notifyListeners();
    unawaited(_monitorLoop());
  }

  void stopMonitoring() {
    _isMonitoring = false;
  }

  Future<void> refresh() async {
    if (_refreshInFlight) return;

    final firstLoad = _status == null;
    if (firstLoad) {
      _isLoading = true;
      notifyListeners();
    }

    _refreshInFlight = true;
    try {
      _status = await _service.fetchStatus();
      _errorMessage = null;
      _lastUpdated = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _refreshInFlight = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _monitorLoop() async {
    while (_isMonitoring) {
      await refresh();
      if (!_isMonitoring) break;
      await Future.delayed(_pollInterval);
    }
  }

  @override
  void dispose() {
    _isMonitoring = false;
    super.dispose();
  }
}
