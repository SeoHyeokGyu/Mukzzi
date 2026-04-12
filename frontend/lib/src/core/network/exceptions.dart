abstract class AppException implements Exception {
  final String message;

  AppException({required this.message});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required super.message});
}

class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message});
}

class NotFoundException extends AppException {
  NotFoundException({required super.message});
}

class BadRequestException extends AppException {
  BadRequestException({required super.message});
}

class ServerException extends AppException {
  ServerException({required super.message});
}

class ParseException extends AppException {
  ParseException({required super.message});
}

class TimeoutException extends AppException {
  TimeoutException({required super.message});
}

class UnknownException extends AppException {
  UnknownException({required super.message});
}
