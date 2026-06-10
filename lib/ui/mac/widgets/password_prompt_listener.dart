import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/password_prompt_state.dart';
import 'package:mole_ui/ui/mac/widgets/sudo_password_dialog.dart';

/// Shows a password dialog whenever [readPrompt] returns a new prompt.
class PasswordPromptListener extends StatefulWidget {
  const PasswordPromptListener({
    super.key,
    required this.listenable,
    required this.readPrompt,
    required this.child,
  });

  final Listenable listenable;
  final PasswordPromptState? Function() readPrompt;
  final Widget child;

  @override
  State<PasswordPromptListener> createState() => _PasswordPromptListenerState();
}

class _PasswordPromptListenerState extends State<PasswordPromptListener> {
  PasswordPromptState? _activePrompt;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.listenable,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowPrompt(widget.readPrompt());
        });
        return child!;
      },
      child: widget.child,
    );
  }

  void _maybeShowPrompt(PasswordPromptState? prompt) {
    if (!mounted) return;
    if (prompt == null || identical(prompt, _activePrompt)) return;
    if (!prompt.completer.isCompleted) {
      _activePrompt = prompt;
      _showDialog(prompt);
    }
  }

  Future<void> _showDialog(PasswordPromptState prompt) async {
    if (!mounted) return;

    final password = await showSudoPasswordDialog(
      context,
      message: prompt.message,
      isRetry: prompt.isRetry,
      errorMessage: prompt.errorMessage,
    );

    if (!prompt.completer.isCompleted) {
      prompt.completer.complete(password);
    }

    if (mounted) {
      setState(() {
        if (identical(_activePrompt, prompt)) {
          _activePrompt = null;
        }
      });
    }
  }
}
