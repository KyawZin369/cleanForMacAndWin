import 'dart:async';

class CleanConfirmPromptState {
  CleanConfirmPromptState({
    required this.title,
    required this.message,
    required this.completer,
    this.confirmLabel = 'Continue',
    this.cancelLabel = 'Skip',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Completer<bool?> completer;
}
