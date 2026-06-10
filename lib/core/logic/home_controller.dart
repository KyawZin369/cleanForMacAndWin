import 'package:flutter/foundation.dart';

/// Shared business logic used by both Mac and Windows UIs.
class HomeController extends ChangeNotifier {
  HomeController();

  int _counter = 0;
  String _statusMessage = 'Ready';

  int get counter => _counter;
  String get statusMessage => _statusMessage;

  void increment() {
    _counter++;
    _statusMessage = 'Counter increased to $_counter';
    notifyListeners();
  }

  void decrement() {
    if (_counter > 0) {
      _counter--;
      _statusMessage = 'Counter decreased to $_counter';
      notifyListeners();
    }
  }

  void reset() {
    _counter = 0;
    _statusMessage = 'Counter reset';
    notifyListeners();
  }
}
