class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, {super.code});
}

class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
