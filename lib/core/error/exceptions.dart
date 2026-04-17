class ServerException implements Exception {
  final String code;

  ServerException(this.code);
}

class ConnectionException implements Exception {}
