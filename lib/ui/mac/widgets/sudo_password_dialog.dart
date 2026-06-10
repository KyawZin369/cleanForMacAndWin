import 'dart:ui';

import 'package:flutter/material.dart';

Future<String?> showSudoPasswordDialog(
  BuildContext context, {
  required String message,
  bool isRetry = false,
  String? errorMessage,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SudoPasswordDialog(
      message: message,
      isRetry: isRetry,
      errorMessage: errorMessage,
    ),
  );
}

class _SudoPasswordDialog extends StatefulWidget {
  const _SudoPasswordDialog({
    required this.message,
    required this.isRetry,
    required this.errorMessage,
  });

  final String message;
  final bool isRetry;
  final String? errorMessage;

  @override
  State<_SudoPasswordDialog> createState() => _SudoPasswordDialogState();
}

class _SudoPasswordDialogState extends State<_SudoPasswordDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Administrator Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
                  ),
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.75),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(widget.isRetry ? 'Try Again' : 'Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
