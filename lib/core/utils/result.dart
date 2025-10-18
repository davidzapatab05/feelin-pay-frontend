import '../errors/failure.dart';

/// Result class for handling success and failure states
sealed class Result<T> {
  const Result();
}

/// Success result
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

/// Failure result
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  String toString() => 'Error(failure: $failure)';
}

/// Extension methods for Result
extension ResultExtensions<T> on Result<T> {
  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is error
  bool get isError => this is Error<T>;

  /// Get data if success, null otherwise
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Error<T>() => null,
  };

  /// Get failure if error, null otherwise
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Error<T>(failure: final failure) => failure,
  };

  /// Transform data if success
  Result<R> map<R>(R Function(T) transform) => switch (this) {
    Success<T>(data: final data) => Success(transform(data)),
    Error<T>(failure: final failure) => Error<R>(failure),
  };

  /// Transform data if success, return same failure if error
  Result<R> flatMap<R>(Result<R> Function(T) transform) => switch (this) {
    Success<T>(data: final data) => transform(data),
    Error<T>(failure: final failure) => Error<R>(failure),
  };

  /// Execute function based on result type
  R when<R>({
    required R Function(T) onSuccess,
    required R Function(Failure) onError,
  }) => switch (this) {
    Success<T>(data: final data) => onSuccess(data),
    Error<T>(failure: final failure) => onError(failure),
  };
}
