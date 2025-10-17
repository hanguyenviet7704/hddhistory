part of '../base.dart';

abstract interface class UseCaseWithParams<Params, Result> {
  TaskEither<AppException, Result> call(Params params);
}

abstract interface class UseCaseWithoutParams<Result> {
  TaskEither<AppException, Result> call();
}

abstract interface class BaseUseCase<Params, Result> {
  TaskEither<AppException, Result> call(Params params);
}

abstract interface class BasePageBreakUseCase<Params extends PageBreakRequest, Result> {
  TaskEither<AppException, BasePageBreak<Result>> call(Params params);
}