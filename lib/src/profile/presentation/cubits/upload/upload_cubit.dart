part of '../../../profile.dart';

@lazySingleton
class UploadCubit extends Cubit<UploadState> with CubitUseCaseHandlerMixin<UploadState> {
  final UploadFileUseCase _uploadFileUseCase;

  UploadCubit(this._uploadFileUseCase) : super(UploadState.initial());

  void uploadFile(UploadFileParams params) async {
    await runUseCase<UploadEntity>(
      usecase: () => _uploadFileUseCase(params),
      buildLoadingState: () => state.copyWith(status: UploadStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: UploadStatus.failure, errorMessage: error));
      },
      onSuccess: (result) {
        emit(state.copyWith(status: UploadStatus.success, uploadResult: result));
      },
    );
  }
}
