/// Represents the base class for all domain failures in the application.
sealed class Failure {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// Validation errors (e.g., empty note title, invalid email).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.error, super.stackTrace});
}

/// Storage errors (e.g., SQLite exception, local file system error).
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.error, super.stackTrace});
}

/// Synchronization errors (e.g., Google Drive API limits, conflict issues).
class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.error, super.stackTrace});
}

/// Network errors (e.g., no internet connection).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.error, super.stackTrace});
}

/// Unknown or unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.error, super.stackTrace});
}
