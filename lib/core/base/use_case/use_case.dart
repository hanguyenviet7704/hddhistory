part of '../base.dart';

abstract interface class UseCaseWithParams<Params, Result> {
  TaskEither<AppException, Result> call(Params params);
}

abstract interface class UseCaseWithoutParams<Result> {
  TaskEither<AppException, Result> call();
}
