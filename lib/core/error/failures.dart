import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A local database error occurred.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Please check your internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load from cache.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
