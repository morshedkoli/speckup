class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    return 'AppException: $message ${code != null ? '($code)' : ''}';
  }
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Network connection failed'])
      : super(message, code: 'network_error');
}

class AuthException extends AppException {
  const AuthException(String message, [String? code])
      : super(message, code: code ?? 'auth_error');
}

class ServerException extends AppException {
  const ServerException(String message, [String? code])
      : super(message, code: code ?? 'server_error');
}

class CacheException extends AppException {
  const CacheException(String message) : super(message, code: 'cache_error');
}
