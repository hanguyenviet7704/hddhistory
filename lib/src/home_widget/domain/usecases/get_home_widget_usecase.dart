part of '../../home_widget.dart';

@lazySingleton
class GetHomeWidgetUseCase implements BaseUseCase<String, HomeWidgetEntity> {
  final IHomeWidgetRepository _repository;

  GetHomeWidgetUseCase(this._repository);

  @override
  TaskEither<AppException, HomeWidgetEntity> call(String params) {
    return _repository.getHomeWidget(params);
  }
}

