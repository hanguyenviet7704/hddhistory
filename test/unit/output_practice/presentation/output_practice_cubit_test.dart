import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeOutputPracticeRepository implements IOutputPracticeRepository {
  _FakeOutputPracticeRepository({
    required this.getConversationHandler,
    required this.getMessagesHandler,
    required this.createConversationHandler,
    required this.sendMessageHandler,
  });

  TaskEither<AppException, OutputPracticeConversationEntity> Function(String sectionId) getConversationHandler;
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> Function(OutputPracticeMessagesRequestEntity request) getMessagesHandler;
  TaskEither<AppException, OutputPracticeConversationEntity> Function(Map<String, dynamic> body) createConversationHandler;
  TaskEither<AppException, List<OutputPracticeMessageEntity>> Function(Map<String, dynamic> body) sendMessageHandler;

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId) => getConversationHandler(sectionId);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(
    OutputPracticeMessagesRequestEntity request,
  ) => getMessagesHandler(request);

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(Map<String, dynamic> body) => createConversationHandler(body);

  @override
  TaskEither<AppException, List<OutputPracticeMessageEntity>> sendOutputPracticeMessage(Map<String, dynamic> body) => sendMessageHandler(body);
}

class _FakeCourseLessonRepository implements ICourseLessonRepository {
  _FakeCourseLessonRepository(this.getCourseLessonHandler);

  TaskEither<AppException, LessonEntity> Function(String id) getCourseLessonHandler;

  @override
  TaskEither<AppException, LessonEntity> getCourseLesson(String id) => getCourseLessonHandler(id);

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(PageBreakRequest request) {
    throw UnimplementedError();
  }
}

void main() {
  group('OutputPracticeCubit', () {
    setUp(() async => setupLocaleCubitForTests());
    tearDown(() async => resetInjectorForTests());

    test('restores summary chips from conversation status and enables input after room join', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.summaryDecisionPending),
        messages: _historyMessages,
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      cubit.preloadEntry(lesson: _lesson(), sectionId: 'section-1');
      await cubit.initialize('section-1');

      expect(cubit.state.entryState, OutputPracticeEntryState.existing);
      expect(cubit.state.timelineItems.map((item) => item.content), ['Hi coach', 'Let us begin']);
      expect(cubit.state.activeActionChips.map((chip) => chip.summaryAction), [
        OutputPracticeSummaryAction.continueDeeper,
        OutputPracticeSummaryAction.newChallenge,
        OutputPracticeSummaryAction.differentScenario,
        OutputPracticeSummaryAction.endPractice,
      ]);
      expect(cubit.state.displayLesson.animation.name, 'Coach Mira');
      expect(cubit.state.isInputEnabled, isFalse);

      cubit.markRoomJoined('conversation-1');

      expect(cubit.state.isInputEnabled, isTrue);
    });

    test('marks failed free-text sends in-place and restores chips', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
        sendMessageResult: TaskEither.left(AppException.unexpected('Socket lost')),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');
      cubit.updateInputText('Need another hint');

      await cubit.sendCurrentInput();

      expect(cubit.state.roomErrorMessage, 'Socket lost');
      expect(cubit.state.pendingMessageText, 'Need another hint');
      expect(cubit.state.timelineItems.single.deliveryStatus, OutputPracticeDeliveryStatus.failed);
      expect(cubit.state.timelineItems.single.content, 'Need another hint');
      expect(cubit.state.activeActionChips, isNotEmpty);
    });

    test('ignores stale room joins and socket events from another conversation', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');

      cubit.markRoomJoined('conversation-2');
      cubit.markRoomJoinFailed('conversation-2', 'stale');
      cubit.handleSocketEvent(
        const OutputPracticeAiStreamEvent.stream(
          conversationId: 'conversation-2',
          content: 'wrong room',
        ),
      );

      expect(cubit.state.joinedRoomId, isEmpty);
      expect(cubit.state.roomErrorMessage, isNull);
      expect(cubit.state.timelineItems, isEmpty);
    });

    test('keeps the optimistic turn when send succeeds without canonical messages', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
        sendMessageResult: TaskEither.right(const []),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');
      cubit.updateInputText('Keep this visible');

      await cubit.sendCurrentInput();

      expect(cubit.state.sendStatus, OutputPracticeSendStatus.idle);
      expect(cubit.state.pendingMessageText, isNull);
      expect(cubit.state.timelineItems.single.content, 'Keep this visible');
      expect(cubit.state.timelineItems.single.deliveryStatus, OutputPracticeDeliveryStatus.confirmed);
    });

    test('classifies typed chip matches as select_option and replaces pending turn with canonical messages', () async {
      final sentBodies = <Map<String, dynamic>>[];
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 3, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ]),
        onSend: sentBodies.add,
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');
      cubit.updateInputText('  TRY AGAIN  ');

      await cubit.sendCurrentInput();

      expect(sentBodies.single['type'], 'select_option');
      expect(sentBodies.single['value'], 7);
      expect(cubit.state.timelineItems.map((item) => item.content), ['Try again', 'Sure, let us retry.']);
      expect(cubit.state.timelineItems.every((item) => item.deliveryStatus == OutputPracticeDeliveryStatus.confirmed), isTrue);
      expect(cubit.state.pendingMessageText, isNull);
    });
  });
}

OutputPracticeCubit _buildCubit({required _FakeOutputPracticeRepository repo}) {
  final courseRepo = _FakeCourseLessonRepository((_) => TaskEither.right(_lesson()));
  return OutputPracticeCubit(
    GetOutputPracticeConversationUseCase(repo),
    GetAllOutputPracticeMessagesUseCase(repo),
    CreateOutputPracticeConversationUseCase(repo),
    SendOutputPracticeMessageUseCase(repo),
    GetCourseLessonUseCase(courseRepo),
  );
}

_FakeOutputPracticeRepository _buildOutputPracticeRepository({
  required OutputPracticeConversationEntity conversation,
  required List<OutputPracticeMessageEntity> messages,
  TaskEither<AppException, List<OutputPracticeMessageEntity>>? sendMessageResult,
  void Function(Map<String, dynamic> body)? onSend,
}) {
  return _FakeOutputPracticeRepository(
    getConversationHandler: (_) => TaskEither.right(conversation),
    getMessagesHandler: (request) => TaskEither.right(
      BasePageBreak(
        currentPage: request.page,
        totalPages: 1,
        items: messages,
      ),
    ),
    createConversationHandler: (_) => TaskEither.right(conversation),
    sendMessageHandler: (body) {
      onSend?.call(body);
      return sendMessageResult ?? TaskEither.right(const []);
    },
  );
}

LessonEntity _lesson() => const LessonEntity(
  id: 'lesson-1',
  title: BaseMultiLanguage(en: 'Output practice'),
  animation: ConversationAvatarEntity(name: 'Coach Mira', url: 'https://example.com/avatar.png'),
);

OutputPracticeConversationEntity _conversation({
  OutputPracticeConversationStatus status = OutputPracticeConversationStatus.active,
}) => OutputPracticeConversationEntity(
  id: 'conversation-1',
  sectionId: 'section-1',
  status: status,
  reply: const OutputPracticeAiReplyEntity(
    options: [
      OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
    ],
  ),
);

const List<OutputPracticeMessageEntity> _historyMessages = [
  OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 2, content: 'Let us begin', role: OutputPracticeMessageRole.assistant),
  OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 1, content: 'Hi coach', role: OutputPracticeMessageRole.user),
];
