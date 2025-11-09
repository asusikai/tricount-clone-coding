import 'app_exception.dart';

typedef ResultFuture<T> = Future<Result<T>>;

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get requireValue {
    if (this case Success<T>(value: final value)) {
      return value;
    }
    throw StateError('Result does not contain a value');
  }

  AppException get requireError {
    if (this case Failure<T>(error: final error)) {
      return error;
    }
    throw StateError('Result does not contain an error');
  }

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    if (this case Success<T>(value: final value)) {
      return onSuccess(value);
    }
    return onFailure(requireError);
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppException error;
}

extension ResultX<T> on Result<T> {
  Result<R> map<R>(R Function(T value) transform) {
    if (this case Success<T>(value: final value)) {
      return Success<R>(transform(value));
    }
    return Failure<R>(requireError);
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    if (this case Success<T>(value: final value)) {
      return transform(value);
    }
    return Failure<R>(requireError);
  }
}

extension ResultFutureUnwrap<T> on ResultFuture<T> {
  Future<T> unwrap() async {
    final result = await this;
    if (result case Success<T>(value: final value)) {
      return value;
    }
    throw result.requireError;
  }
}
