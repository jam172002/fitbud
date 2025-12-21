class AuthResult {
  final bool ok;
  final String message;
  final String code;

  const AuthResult._(this.ok, this.message, this.code);

  factory AuthResult.success([String message = 'Success']) =>
      AuthResult._(true, message, 'ok');

  factory AuthResult.fail(String message, {String code = 'error'}) =>
      AuthResult._(false, message, code);
}
