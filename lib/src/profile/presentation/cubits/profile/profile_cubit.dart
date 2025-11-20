part of '../../../profile.dart';

@lazySingleton
class ProfileCubit extends HydratedCubit<ProfileState> with CubitUseCaseHandlerMixin<ProfileState> {
  final GetUserUseCase _getUseCase;
  final UpdateUserUseCase _updateUseCase;

  ProfileCubit(
    this._getUseCase,
    this._updateUseCase,
  ) : super(ProfileState.initial());

  @override
  ProfileState fromJson(Map<String, dynamic> json) => ProfileState.fromJson(json);

  @override
  Map<String, dynamic> toJson(ProfileState state) => state.toJson();

  void reset() => emit(ProfileState.initial());
  void setUser(UserEntity user) => emit(state.copyWith(user: user));

  void loadUser() async {
    if (state.user.id.isEmpty) return;
    await runUseCase<UserEntity>(
      usecase: () => _getUseCase(state.user.id),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProfileStatus.success, user: item));
      },
    );
  }

  void updateUser(UserEntity entity) async {
    await runUseCase<UserEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (updatedItem) {
        emit(state.copyWith(status: ProfileStatus.success, user: updatedItem));
      },
    );
  }
}
