class RepoException implements Exception {
  final String code;
  final String message;
  RepoException(this.code, this.message);

  @override
  String toString() => 'RepoException($code): $message';
}

class NotFoundException extends RepoException {
  NotFoundException(String message) : super('not_found', message);
}

class PermissionException extends RepoException {
  PermissionException(String message) : super('permission_denied', message);
}

class ValidationException extends RepoException {
  ValidationException(String message) : super('invalid_argument', message);
}
