part of '../../../profile.dart';

@lazySingleton
class UploadCubit extends Cubit<UploadState> with CubitUseCaseHandlerMixin<UploadState> {
  final UploadFileUseCase _uploadFileUseCase;

  UploadCubit(this._uploadFileUseCase) : super(UploadState.initial());

  void uploadFile(
    UploadFileParams params, {
    required void Function(UploadEntity result) onSuccess,
    required void Function(String error) onFailure,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    await runUseCase<UploadEntity>(
      usecase: () => _uploadFileUseCase(params),
      buildLoadingState: () => state.copyWith(status: UploadStatus.loading),
      onFailure: onFailure,
      onSuccess: onSuccess,
    );
  }
}
