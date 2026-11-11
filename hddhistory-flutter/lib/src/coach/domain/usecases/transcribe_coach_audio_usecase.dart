part of '../../coach.dart';

@lazySingleton
class TranscribeCoachAudioUseCase {
  final ICoachRepository _repository;

  TranscribeCoachAudioUseCase(this._repository);

  TaskEither<AppException, String> call({
    required String base64Audio,
    required String mimeType,
    required String locale,
  }) {
    return _repository.transcribe(
      base64Audio: base64Audio,
      mimeType: mimeType,
      locale: locale,
    );
  }
}
