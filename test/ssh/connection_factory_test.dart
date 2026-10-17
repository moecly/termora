import 'package:flutter_test/flutter_test.dart';
import 'package:termora/ssh/connection_factory.dart';

void main() {
  test('a stored password is returned without prompting', () async {
    var prompted = false;
    var remembered = false;
    final result = await resolvePassword(
      stored: 'secret',
      prompt: () async {
        prompted = true;
        return 'typed';
      },
      remember: (_) async => remembered = true,
    );
    expect(result, 'secret');
    expect(prompted, isFalse);
    expect(remembered, isFalse);
  });

  test('a missing password prompts once and remembers the entry', () async {
    String? remembered;
    final result = await resolvePassword(
      stored: null,
      prompt: () async => 'typed',
      remember: (value) async => remembered = value,
    );
    expect(result, 'typed');
    expect(remembered, 'typed');
  });

  test('an empty stored password is treated as missing', () async {
    String? remembered;
    final result = await resolvePassword(
      stored: '',
      prompt: () async => 'typed',
      remember: (value) async => remembered = value,
    );
    expect(result, 'typed');
    expect(remembered, 'typed');
  });

  test('a cancelled prompt returns null and remembers nothing', () async {
    var remembered = false;
    final result = await resolvePassword(
      stored: null,
      prompt: () async => null,
      remember: (_) async => remembered = true,
    );
    expect(result, isNull);
    expect(remembered, isFalse);
  });
}
