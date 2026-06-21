import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/clean_confirm_prompt_state.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

/// Shows a confirmation dialog when [readPrompt] returns a new prompt.
class CleanConfirmListener extends StatefulWidget {
  const CleanConfirmListener({
    super.key,
    required this.listenable,
    required this.readPrompt,
    required this.child,
  });

  final Listenable listenable;
  final CleanConfirmPromptState? Function() readPrompt;
  final Widget child;

  @override
  State<CleanConfirmListener> createState() => _CleanConfirmListenerState();
}

class _CleanConfirmListenerState extends State<CleanConfirmListener> {
  CleanConfirmPromptState? _activePrompt;

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

  void _maybeShowPrompt(CleanConfirmPromptState? prompt) {
    if (!mounted) return;
    if (prompt == null || identical(prompt, _activePrompt)) return;
    if (!prompt.completer.isCompleted) {
      _activePrompt = prompt;
      _showDialog(prompt);
    }
  }

  Future<void> _showDialog(CleanConfirmPromptState prompt) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(prompt.title),
          content: SingleChildScrollView(
            child: Text(
              prompt.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF323130),
              ),
            ),
          ),
          actions: [
            WindowsSecondaryButton(
              label: prompt.cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            WindowsPrimaryButton(
              label: prompt.confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (!prompt.completer.isCompleted) {
      prompt.completer.complete(confirmed);
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
