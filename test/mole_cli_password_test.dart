import 'package:flutter_test/flutter_test.dart';
import 'package:mole_ui/core/services/mole_cli_password.dart';

void main() {
  group('MoleCliPassword line classification', () {
    test('treats clean section headers as progress, not password prompts', () {
      expect(
        MoleCliPassword.isSudoSectionHeader('➤ App caches'),
        isTrue,
      );
      expect(
        MoleCliPassword.isPasswordPromptLine('➤ App caches'),
        isFalse,
      );
      expect(
        MoleCliPassword.isPasswordPromptLine('➤ User essentials'),
        isFalse,
      );
    });

    test('detects credential prompts', () {
      expect(
        MoleCliPassword.isPasswordPromptLine('Password:'),
        isTrue,
      );
      expect(
        MoleCliPassword.isPasswordPromptLine('Enter your credentials'),
        isTrue,
      );
    });

    test('detects optimize admin requirement message', () {
      expect(
        MoleCliPassword.isOptimizeAdminRequired(
          '➤ System optimization requires admin access',
        ),
        isTrue,
      );
    });
  });
}
