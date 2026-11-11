part of '../../coach.dart';

/// The microphone, from tap to text.
///
/// Its own object rather than a limb of [CoachCubit] because the two have
/// nothing to say to each other beyond one string: this owns a recorder, a
/// permission and a temp file, and the cubit owns a conversation. Keeping them
/// apart means a Coach turn can be tested without a microphone anywhere near it.
///
/// The recording is deleted the moment it has been read. The design's rule is
/// that speech becomes text and the audio is dropped, and the only way to keep
/// that promise is to never let the file outlive the sentence.
@injectable
class CoachRecorder {
  final TranscribeCoachAudioUseCase _transcribe;

  CoachRecorder(this._transcribe);

  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  bool get isRecording => _path != null;

  /// Returns false when the microphone was refused — the caller leaves the
  /// composer exactly as it was rather than explaining anything.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/coach_turn.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );
    _path = path;

    return true;
  }

  /// Stops, transcribes, deletes. Returns '' on any failure — a microphone that
  /// heard nothing is not an error worth interrupting somebody with.
  Future<String> stopAndTranscribe(String locale) async {
    final path = _path;
    _path = null;
    if (path == null) return '';

    try {
      await _recorder.stop();

      final file = File(path);
      if (!file.existsSync()) return '';

      final bytes = await file.readAsBytes();
      // Deleted before the network call, not after: whatever happens upstream,
      // the recording is already gone from the device.
      await file.delete();

      if (bytes.isEmpty) return '';

      final result = await _transcribe(
        base64Audio: base64Encode(bytes),
        mimeType: 'audio/mp4',
        locale: locale,
      ).run();

      return result.getOrElse((_) => '');
    } catch (_) {
      return '';
    }
  }

  Future<void> cancel() async {
    final path = _path;
    _path = null;
    if (path == null) return;

    try {
      await _recorder.stop();
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Nothing to report: the reader cancelled, and a failure to clean up a
      // temp file is not their problem.
    }
  }

  Future<void> dispose() => _recorder.dispose();
}
