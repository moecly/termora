import '../data/models.dart';

/// Credentials used for a single connection attempt.
class AuthConfig {
  const AuthConfig({
    required this.method,
    this.password,
    this.privateKeyPem,
    this.passphrase,
  });

  final AuthMethod method;

  /// Login password (from the secret store or a one-off prompt).
  final String? password;

  /// Full PEM private key.
  final String? privateKeyPem;

  /// Private key passphrase, if any.
  final String? passphrase;
}
