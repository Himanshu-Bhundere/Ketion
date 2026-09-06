import '../errors/failures.dart';

/// A generic wrapper to encapsulate either a successful value `T` or a `Failure`.
sealed class Result<T> {
  const Result();

  /// Executes [onSuccess] if the result is [Success], or [onFailure] if it is [Error].
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  );

  bool get isError => this is Error<T>;
  bool get isSuccess => this is Success<T>;
  T? get valueOrNull => fold((value) => value, (failure) => null);
  Success<T>? get asValue => this is Success<T> ? this as Success<T> : null;
}

/// Represents a successful operation.
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    return onSuccess(value);
  }
}

/// Represents a failed operation.
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    return onFailure(failure);
  }
}
