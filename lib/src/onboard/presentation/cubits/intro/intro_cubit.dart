part of '../../../onboard.dart';

@lazySingleton
class IntroCubit extends Cubit<IntroState> {
  IntroCubit() : super(IntroState.initial());

  void setIntros(List<OnboardIntroEntity> intros) => emit(state.copyWith(intros: intros));

  void setPage(int page) {
    if (page < 0 || page >= state.intros.length) return;
    emit(state.copyWith(currentPage: page));
  }
}
