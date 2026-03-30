import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeOutputPracticeApi implements OutputPracticeApi {
  _FakeOutputPracticeApi(this.getMessagesHandler);

  Future<BaseResponse<BasePageBreak<OutputPracticeMessageModel>>> Function(OutputPracticeMessagesRequestEntity request) getMessagesHandler;

  @override
  Future<BaseResponse<BasePageBreak<OutputPracticeMessageModel>>> getAllOutputPracticeMessages(
    OutputPracticeMessagesRequestEntity request,
  ) => getMessagesHandler(request);

  @override
  Future<BaseResponse<OutputPracticeConversationModel>> createOutputPracticeConversation(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  Future<BaseResponse<OutputPracticeConversationModel>> getOutputPracticeConversation(String sectionId) {
    throw UnimplementedError();
  }

  @override
  Future<BaseResponseList<OutputPracticeMessageModel>> sendOutputPracticeMessage(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}

class _FakeOutputPracticeLocalDataSource implements OutputPracticeLocalDataSource {
  final Map<String, List<OutputPracticeMessageModel>> messagesByConversationId = <String, List<OutputPracticeMessageModel>>{};

  @override
  Future<List<OutputPracticeMessageModel>> getCachedMessages(String conversationId) async => messagesByConversationId[conversationId] ?? const [];

  @override
  Future<void> cacheMessages(String conversationId, List<OutputPracticeMessageModel> models) async {
    messagesByConversationId[conversationId] = models;
  }

  @override
  Future<OutputPracticeConversationModel?> getCachedConversation(String sectionId) async => null;

  @override
  Future<void> cacheConversation(String sectionId, OutputPracticeConversationModel model) async {}

  @override
  Future<void> clearConversation(String sectionId) async {}

  @override
  Future<void> clearMessages(String conversationId) async {
    messagesByConversationId.remove(conversationId);
  }
}

void main() {
  group('OutputPracticeRepository', () {
    setUp(() async {
      await setupLocaleCubitForTests();
      AppDI.injector.registerSingleton<ITrackingService>(
        AppTrackingService(NoOpTrackingService()),
      );
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('merges paged history into the conversation cache instead of overwriting prior pages', () async {
      final localDataSource = _FakeOutputPracticeLocalDataSource()
        ..messagesByConversationId['conversation-1'] = const [
          OutputPracticeMessageModel(conversationId: 'conversation-1', seq: 1, content: 'First', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageModel(conversationId: 'conversation-1', seq: 2, content: 'Second', role: OutputPracticeMessageRole.assistant),
        ];
      final repository = OutputPracticeRepository(
        _FakeOutputPracticeApi(
          (_) async => const BaseResponse(
            status: true,
            data: BasePageBreak(
              currentPage: 2,
              totalPages: 2,
              items: [
                OutputPracticeMessageModel(conversationId: 'conversation-1', seq: 3, content: 'Third', role: OutputPracticeMessageRole.user),
                OutputPracticeMessageModel(conversationId: 'conversation-1', seq: 4, content: 'Fourth', role: OutputPracticeMessageRole.assistant),
              ],
            ),
          ),
        ),
        localDataSource,
      );

      final result = await repository
          .getAllOutputPracticeMessages(
            const OutputPracticeMessagesRequestEntity(
              conversationId: 'conversation-1',
              page: 2,
            ),
          )
          .run();

      final cachedMessages = await localDataSource.getCachedMessages('conversation-1');
      expect(result.getOrElse((_) => const BasePageBreak()).items.map((item) => item.content), ['Third', 'Fourth']);
      expect(cachedMessages.map((item) => item.content), ['First', 'Second', 'Third', 'Fourth']);
    });
  });
}
