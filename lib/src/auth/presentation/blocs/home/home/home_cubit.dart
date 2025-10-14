part of '../../blocs.dart';

@lazySingleton
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState.initial());

  void setHomeIndex(HomeModule module) {
    emit(state.copyWith(homeModule: module));
  }
}
