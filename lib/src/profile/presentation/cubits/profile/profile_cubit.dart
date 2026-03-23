part of '../../../profile.dart';

@lazySingleton
class ProfileCubit extends HydratedCubit<ProfileState> with CubitUseCaseHandlerMixin<ProfileState> {
  final GetUserUseCase _getUseCase;
  final UpdateUserUseCase _updateUseCase;
  final GetUserIapSubscriptionsUseCase _getUserIapSubscriptionsUseCase;

  ProfileCubit(
    this._getUseCase,
    this._updateUseCase,
    this._getUserIapSubscriptionsUseCase,
  ) : super(ProfileState.initial());

  @override
  ProfileState fromJson(Map<String, dynamic> json) => ProfileState.fromJson(json);

  @override
  Map<String, dynamic> toJson(ProfileState state) => state.toJson();

  void reset() => emit(ProfileState.initial());
  void setUser(UserEntity user) => emit(state.copyWith(user: user));

  Future<void> loadUser({bool isInit = false}) async {
    if (state.user.id.isEmpty) return;
    await runUseCase<UserEntity>(
      usecase: () => _getUseCase(state.user.id),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProfileStatus.success, user: item));
        loadUserIapSubscriptions();
      },
    );
  }

  Future<void> loadUserIapSubscriptions() async {
    if (state.user.id.isEmpty) return;
    await runUseCase<IapSubscriptionEntity>(
      usecase: () => _getUserIapSubscriptionsUseCase(state.user.id),
      onSuccess: (items) {
        if (items.id.isEmpty) {
          UserEntity user = state.user.copyWith(iapSubscriptions: []);
          emit(state.copyWith(user: user));
          return;
        }
        UserEntity user = state.user.copyWith(iapSubscriptions: [items]);
        emit(state.copyWith(user: user));
      },
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
    );
  }

  void updateUser(UserEntity entity) async {
    if (entity.id.isEmpty) return;
    if (entity.name == state.user.name) return;

    Map<String, dynamic> params = {
      'id': entity.id,
      'name': entity.name,
    };

    await runUseCase<UserEntity>(
      usecase: () => _updateUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProfileStatus.failure, errorMessage: error));
      },
      onSuccess: (updatedItem) {
        emit(state.copyWith(status: ProfileStatus.success));
        loadUser();
      },
    );
  }
}
