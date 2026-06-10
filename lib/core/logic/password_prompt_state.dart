import 'dart:async';

class PasswordPromptState {
  PasswordPromptState({
    required this.message,
    required this.completer,
    this.isRetry = false,
    this.errorMessage,
  });

  final String message;
  final bool isRetry;
  final String? errorMessage;
  final Completer<String?> completer;
}
