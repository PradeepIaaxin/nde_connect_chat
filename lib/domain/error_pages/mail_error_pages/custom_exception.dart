class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class DataFormatException implements Exception {
  final String message;
  DataFormatException(this.message);

  @override
  String toString() => 'DataFormatException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);

  @override
  String toString() => 'UnknownException: $message';
}
