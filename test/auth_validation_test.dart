import 'package:cuan_mobile/features/auth/presentation/login_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Client-side validation rules for the auth form (QA-004).
void main() {
  group('validateAuthForm', () {
    test('login: empty email is rejected', () {
      expect(
        validateAuthForm(
          registerMode: false,
          name: '',
          email: '',
          password: 'secret123',
        ),
        isNotNull,
      );
    });

    test('login: malformed email is rejected', () {
      for (final bad in ['nope', 'a@b', 'a b@c.com', '@c.com', 'a@']) {
        expect(
          validateAuthForm(
            registerMode: false,
            name: '',
            email: bad,
            password: 'secret123',
          ),
          isNotNull,
          reason: 'expected "$bad" to be rejected',
        );
      }
    });

    test('login: empty password is rejected', () {
      expect(
        validateAuthForm(
          registerMode: false,
          name: '',
          email: 'user@cuan.app',
          password: '',
        ),
        isNotNull,
      );
    });

    test('login: valid input passes', () {
      expect(
        validateAuthForm(
          registerMode: false,
          name: '',
          email: 'user@cuan.app',
          password: 'secret123',
        ),
        isNull,
      );
    });

    test('register: empty name is rejected', () {
      expect(
        validateAuthForm(
          registerMode: true,
          name: '   ',
          email: 'user@cuan.app',
          password: 'secret123',
        ),
        isNotNull,
      );
    });

    test('register: short password is rejected', () {
      expect(
        validateAuthForm(
          registerMode: true,
          name: 'Arif',
          email: 'user@cuan.app',
          password: 'short7',
        ),
        isNotNull,
      );
    });

    test('register: valid input passes', () {
      expect(
        validateAuthForm(
          registerMode: true,
          name: 'Arif',
          email: 'user@cuan.app',
          password: 'secret123',
        ),
        isNull,
      );
    });

    test('email with surrounding whitespace is trimmed before checking', () {
      expect(
        validateAuthForm(
          registerMode: false,
          name: '',
          email: '  user@cuan.app  ',
          password: 'secret123',
        ),
        isNull,
      );
    });
  });
}
