sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);
  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(String message, {this.statusCode}) : super(message);
}
