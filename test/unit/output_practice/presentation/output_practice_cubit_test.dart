import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeOutputPracticeRepository implements IOutputPracticeRepository {
  _FakeOutputPracticeRepository({
    required this.getConversationHandler,
    required this.getUsageHandler,
    required this.getMessagesHandler,
    required this.createConversationHandler,
    required this.sendMessageHandler,
  });

  TaskEither<AppException, OutputPracticeConversationEntity> Function(String sectionId) getConversationHandler;
  TaskEither<AppException, OutputPracticeConversationUsageEntity> Function(String sectionId) getUsageHandler;
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> Function(OutputPracticeMessagesRequestEntity request) getMessagesHandler;
  TaskEither<AppException, OutputPracticeConversationEntity> Function(Map<String, dynamic> body) createConversationHandler;
  TaskEither<AppException, List<OutputPracticeMessageEntity>> Function(Map<String, dynamic> body) sendMessageHandler;

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId) => getConversationHandler(sectionId);

  @override
  TaskEither<AppException, OutputPracticeConversationUsageEntity> getOutputPracticeConversationUsage(String sectionId) => getUsageHandler(sectionId);

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

    test('restores the final summary chip contract and keeps text input disabled after room join', () async {
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
      expect(cubit.state.activeActionChips, isEmpty);

      cubit.markRoomJoined('conversation-1');

      expect(cubit.state.activeActionChips.map((chip) => chip.summaryAction), [
        OutputPracticeSummaryAction.endPractice,
        OutputPracticeSummaryAction.startANewConversation,
      ]);
      expect(cubit.state.displayLesson.animation.name, 'Coach Mira');
      expect(cubit.state.isInputEnabled, isFalse);

      expect(cubit.state.isInputEnabled, isFalse);
      expect(cubit.state.canSubmitActionChip, isTrue);
    });

    test('hides summary chips when reopening during a pending summary turn', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.summaryDecisionPending),
        messages: const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 1, content: 'Would you like to continue?', role: OutputPracticeMessageRole.assistant),
          OutputPracticeMessageEntity(
            conversationId: 'conversation-1',
            seq: 2,
            content: 'End practice',
            type: OutputPracticeMessageType.summaryDecision,
            role: OutputPracticeMessageRole.user,
          ),
        ],
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');

      expect(cubit.state.activeActionChips, isEmpty);
    });

    test('marks failed free-text sends in-place and restores chips', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.active),
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
      expect(cubit.state.activeActionChips, isEmpty);
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
        conversation: _conversation(status: OutputPracticeConversationStatus.active),
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

    test('submits option chips as select_option and replaces pending turn with canonical messages', () async {
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

      await cubit.sendActionChip(cubit.state.activeActionChips.single, committedText: 'Try again');

      expect(sentBodies.single['type'], 'select_option');
      expect(sentBodies.single['value'], 7);
      expect(cubit.state.timelineItems.map((item) => item.content), ['Try again', 'Sure, let us retry.']);
      expect(cubit.state.timelineItems.every((item) => item.deliveryStatus == OutputPracticeDeliveryStatus.confirmed), isTrue);
      expect(cubit.state.pendingMessageText, isNull);
    });

    test('does not show select-option chips when conversation status is active', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.active),
        messages: const [],
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');

      expect(cubit.state.activeActionChips, isEmpty);
    });

    test('keeps current option chips visible when the last confirmed message is assistant', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(
          options: const [
            OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
            OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
          ],
        ),
        messages: const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 1, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 2, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ],
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      expect(cubit.state.activeActionChips.map((chip) => chip.label), ['Try again', 'New branch']);
    });

    test('keeps action chips hidden until history loading completes', () async {
      final historyCompleter = Completer<void>();
      final repo = _FakeOutputPracticeRepository(
        getConversationHandler: (_) => TaskEither.right(
          _conversation(
            options: const [
              OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
            ],
          ),
        ),
        getUsageHandler: (_) => TaskEither.right(const OutputPracticeConversationUsageEntity()),
        getMessagesHandler: (request) => TaskEither(() async {
          await historyCompleter.future;
          return right(
            BasePageBreak(
              currentPage: request.page,
              totalPages: 1,
              items: const [],
            ),
          );
        }),
        createConversationHandler: (_) => TaskEither.right(_conversation()),
        sendMessageHandler: (_) => TaskEither.right(const []),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      final initializeFuture = cubit.initialize('section-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.historyStatus, OutputPracticeHistoryStatus.loading);
      expect(cubit.state.activeActionChips, isEmpty);

      historyCompleter.complete();
      await initializeFuture;

      expect(cubit.state.historyStatus, OutputPracticeHistoryStatus.success);
      expect(cubit.state.activeActionChips, isEmpty);

      cubit.markRoomJoined('conversation-1');

      expect(cubit.state.activeActionChips.map((chip) => chip.label), ['Try again']);
    });

    test('keeps selected chips hidden until the socket turn refreshes conversation state', () async {
      var conversationReadCount = 0;
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
        getConversationHandler: (_) {
          conversationReadCount += 1;
          return TaskEither.right(
            switch (conversationReadCount) {
              1 || 2 => _conversation(),
              _ => _conversation(
                lastSeq: 4,
                options: const [
                  OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
                ],
              ),
            },
          );
        },
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 3, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ]),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      await cubit.sendActionChip(cubit.state.activeActionChips.single, committedText: 'Try again');

      expect(cubit.state.activeActionChips, isEmpty);

      await cubit.handleSocketEvent(const OutputPracticeAiStreamEvent.end(conversationId: 'conversation-1'));

      expect(cubit.state.activeActionChips.map((chip) => chip.label), ['New branch']);
    });

    test('does not re-show remaining options before the select-option turn ends', () async {
      var conversationReadCount = 0;
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(
          options: const [
            OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
            OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
          ],
        ),
        messages: const [],
        getConversationHandler: (_) {
          conversationReadCount += 1;
          return TaskEither.right(
            switch (conversationReadCount) {
              1 => _conversation(
                options: const [
                  OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
                  OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
                ],
              ),
              2 => _conversation(
                lastSeq: 4,
                options: const [
                  OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
                ],
              ),
              _ => _conversation(
                status: OutputPracticeConversationStatus.active,
                lastSeq: 5,
                options: const [
                  OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
                ],
              ),
            },
          );
        },
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 3, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ]),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      await cubit.sendActionChip(cubit.state.activeActionChips.firstWhere((chip) => chip.label == 'Try again'), committedText: 'Try again');

      expect(cubit.state.activeActionChips, isEmpty);

      await cubit.handleSocketEvent(const OutputPracticeAiStreamEvent.end(conversationId: 'conversation-1'));

      expect(cubit.state.activeActionChips, isEmpty);
    });

    test('does not re-show summary chips before the summary-decision turn ends', () async {
      var conversationReadCount = 0;
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.summaryDecisionPending),
        messages: const [],
        getConversationHandler: (_) {
          conversationReadCount += 1;
          return TaskEither.right(
            switch (conversationReadCount) {
              1 => _conversation(status: OutputPracticeConversationStatus.summaryDecisionPending),
              2 => _conversation(
                status: OutputPracticeConversationStatus.summaryDecisionPending,
                lastSeq: 4,
              ),
              _ => _conversation(
                status: OutputPracticeConversationStatus.finished,
                lastSeq: 5,
              ),
            },
          );
        },
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(
            conversationId: 'conversation-1',
            seq: 3,
            content: 'End practice',
            type: OutputPracticeMessageType.summaryDecision,
            role: OutputPracticeMessageRole.user,
          ),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Thanks for practicing.', role: OutputPracticeMessageRole.assistant),
        ]),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      final endPracticeChip = cubit.state.activeActionChips.firstWhere((chip) => chip.summaryAction == OutputPracticeSummaryAction.endPractice);
      await cubit.sendActionChip(endPracticeChip, committedText: 'End practice');

      expect(cubit.state.activeActionChips, isEmpty);

      await cubit.handleSocketEvent(const OutputPracticeAiStreamEvent.end(conversationId: 'conversation-1'));

      expect(cubit.state.activeActionChips.map((chip) => chip.summaryAction), [
        OutputPracticeSummaryAction.startANewConversation,
      ]);
    });

    test('does not restore stale chips when the socket end refresh still returns the old conversation', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(),
        messages: const [],
        getConversationHandler: (_) => TaskEither.right(_conversation()),
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 3, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ]),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      await cubit.sendActionChip(cubit.state.activeActionChips.single, committedText: 'Try again');
      await cubit.handleSocketEvent(const OutputPracticeAiStreamEvent.end(conversationId: 'conversation-1'));

      expect(cubit.state.activeActionChips, isEmpty);
    });

    test('keeps consumed options hidden even when an advanced conversation returns the same option set', () async {
      var conversationReadCount = 0;
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(
          options: const [
            OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
            OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
          ],
        ),
        messages: const [],
        getConversationHandler: (_) {
          conversationReadCount += 1;
          return TaskEither.right(
            _conversation(
              lastSeq: conversationReadCount >= 3 ? 4 : 0,
              options: const [
                OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
                OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
              ],
            ),
          );
        },
        sendMessageResult: TaskEither.right(const [
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 3, content: 'Try again', role: OutputPracticeMessageRole.user),
          OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 4, content: 'Sure, let us retry.', role: OutputPracticeMessageRole.assistant),
        ]),
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      await cubit.sendActionChip(cubit.state.activeActionChips.firstWhere((chip) => chip.label == 'Try again'), committedText: 'Try again');
      await cubit.handleSocketEvent(const OutputPracticeAiStreamEvent.end(conversationId: 'conversation-1'));

      expect(cubit.state.activeActionChips.map((chip) => chip.label), ['Try again', 'New branch']);
    });

    test('exposes start-a-new-conversation as the only action for limited conversations', () async {
      final repo = _buildOutputPracticeRepository(
        conversation: _conversation(status: OutputPracticeConversationStatus.conversationLimitInMonth),
        messages: _historyMessages,
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      expect(cubit.state.isInputEnabled, isFalse);
      expect(cubit.state.canSubmitActionChip, isTrue);
      expect(cubit.state.activeActionChips.map((chip) => chip.summaryAction), [
        OutputPracticeSummaryAction.startANewConversation,
      ]);
    });

    test('startANewConversation uses create/get/history and refreshes usage without using send', () async {
      final sentBodies = <Map<String, dynamic>>[];
      final createdBodies = <Map<String, dynamic>>[];
      var getConversationCount = 0;
      var usageReadCount = 0;
      final repo = _FakeOutputPracticeRepository(
        getConversationHandler: (_) => TaskEither.right(
          switch (++getConversationCount) {
            1 => _conversation(status: OutputPracticeConversationStatus.finished),
            _ => _conversation(
              conversationId: 'conversation-2',
              status: OutputPracticeConversationStatus.selectOptionPending,
              options: const [
                OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
              ],
            ),
          },
        ),
        getUsageHandler: (_) => TaskEither.right(
          OutputPracticeConversationUsageEntity(
            remainingInThisMonth: ++usageReadCount == 1 ? 2 : 2,
            monthlyLimit: 3,
          ),
        ),
        getMessagesHandler: (request) => TaskEither.right(
          BasePageBreak(
            currentPage: request.page,
            totalPages: 1,
            items: const [
              OutputPracticeMessageEntity(conversationId: 'conversation-2', seq: 1, content: 'Fresh start', role: OutputPracticeMessageRole.assistant),
            ],
          ),
        ),
        createConversationHandler: (body) {
          createdBodies.add(body);
          return TaskEither.right(
            _conversation(
              conversationId: 'conversation-2',
              status: OutputPracticeConversationStatus.selectOptionPending,
              options: const [
                OutputPracticeAiReplyOptionEntity(value: 11, label: 'New branch'),
              ],
            ),
          );
        },
        sendMessageHandler: (body) {
          sentBodies.add(body);
          return TaskEither.right(const []);
        },
      );
      final cubit = _buildCubit(repo: repo);
      addTearDown(cubit.close);

      await cubit.initialize('section-1');
      cubit.markRoomJoined('conversation-1');

      await cubit.sendActionChip(
        cubit.state.activeActionChips.singleWhere((chip) => chip.summaryAction == OutputPracticeSummaryAction.startANewConversation),
        committedText: 'Start a new conversation',
      );

      expect(createdBodies.single['sectionId'], 'section-1');
      expect(sentBodies, isEmpty);
      expect(cubit.state.currentConversationId, 'conversation-2');
      expect(cubit.state.conversationUsage.remainingInThisMonth, 2);
      expect(usageReadCount, 1);
      expect(cubit.state.timelineItems.map((item) => item.content), ['Fresh start']);
    });
  });
}

OutputPracticeCubit _buildCubit({required _FakeOutputPracticeRepository repo}) {
  final courseRepo = _FakeCourseLessonRepository((_) => TaskEither.right(_lesson()));
  return OutputPracticeCubit(
    GetOutputPracticeConversationUseCase(repo),
    GetOutputPracticeConversationUsageUseCase(repo),
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
  TaskEither<AppException, OutputPracticeConversationEntity> Function(String sectionId)? getConversationHandler,
  TaskEither<AppException, OutputPracticeConversationUsageEntity> Function(String sectionId)? getUsageHandler,
  void Function(Map<String, dynamic> body)? onSend,
}) {
  return _FakeOutputPracticeRepository(
    getConversationHandler: getConversationHandler ?? (_) => TaskEither.right(conversation),
    getUsageHandler: getUsageHandler ?? (_) => TaskEither.right(const OutputPracticeConversationUsageEntity()),
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
  String conversationId = 'conversation-1',
  OutputPracticeConversationStatus status = OutputPracticeConversationStatus.selectOptionPending,
  int lastSeq = 0,
  List<OutputPracticeAiReplyOptionEntity> options = const [
    OutputPracticeAiReplyOptionEntity(value: 7, label: 'Try again'),
  ],
}) => OutputPracticeConversationEntity(
  id: conversationId,
  sectionId: 'section-1',
  lastSeq: lastSeq,
  status: status,
  reply: OutputPracticeAiReplyEntity(
    options: options,
  ),
);

const List<OutputPracticeMessageEntity> _historyMessages = [
  OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 2, content: 'Let us begin', role: OutputPracticeMessageRole.assistant),
  OutputPracticeMessageEntity(conversationId: 'conversation-1', seq: 1, content: 'Hi coach', role: OutputPracticeMessageRole.user),
];
