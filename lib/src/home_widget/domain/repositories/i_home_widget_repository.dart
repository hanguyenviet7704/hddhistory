part of '../../home_widget.dart';

abstract class IHomeWidgetRepository {
  TaskEither<AppException, HomeWidgetEntity> getHomeWidget(String id);
  
}

