part of '../../../profile.dart';

@lazySingleton
class ProfileCubit extends Cubit<ProfileState> with CubitUseCaseHandlerMixin<ProfileState> {
  final GetAllUsersUseCase _getAllUseCase;
  final GetUserUseCase _getUseCase;
  final CreateUserUseCase _createUseCase;
  final UpdateUserUseCase _updateUseCase;
  final DeleteUserUseCase _deleteUseCase;

  ProfileCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(ProfileState.initial());

  void loadAllUsers({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == ProfileStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<UserEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: ProfileStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadUser(String id) async {
    await runUseCase<UserEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: ProfileStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createUser(UserEntity entity) async {
    await runUseCase<UserEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ProfileStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  void updateUser(UserEntity entity) async {
    await runUseCase<UserEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ProfileStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  void deleteUser(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: ProfileStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ProfileStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}
