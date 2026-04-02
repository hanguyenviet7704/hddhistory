import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeOutputPracticeRepository implements IOutputPracticeRepository {
  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(OutputPracticeMessagesRequestEntity request) {
    return TaskEither.right(
      BasePageBreak(
        currentPage: request.page,
        totalPages: 1,
        items: const [],
      ),
    );
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId) {
    return TaskEither.right(
      const OutputPracticeConversationEntity(
        id: 'conversation-1',
        sectionId: 'section-1',
        status: OutputPracticeConversationStatus.active,
      ),
    );
  }

  @override
  TaskEither<AppException, OutputPracticeConversationUsageEntity> getOutputPracticeConversationUsage(String sectionId) {
    return TaskEither.right(const OutputPracticeConversationUsageEntity());
  }

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, List<OutputPracticeMessageEntity>> sendOutputPracticeMessage(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}

class _FakeCourseLessonRepository implements ICourseLessonRepository {
  @override
  TaskEither<AppException, LessonEntity> getCourseLesson(String id) => TaskEither.right(const LessonEntity());

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(PageBreakRequest request) {
    throw UnimplementedError();
  }
}

class _FakeSocketRepository implements IOutputPracticeSocketRepository {
  final _joinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _joinErrorController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventController = StreamController<OutputPracticeAiStreamEvent>.broadcast();

  @override
  bool get isConnected => true;

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  void joinRoom(String roomId) {}

  @override
  void leaveRoom(String roomId) {}

  @override
  Stream<Map<String, dynamic>> onJoinedRoom() => _joinedController.stream;

  @override
  Stream<Map<String, dynamic>> onJoinRoomError() => _joinErrorController.stream;

  @override
  Stream<OutputPracticeAiStreamEvent> onOutputPracticeEvent() => _eventController.stream;
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('keeps the page open when the system back action is invoked', (tester) async {
    final outputRepo = _FakeOutputPracticeRepository();
    final socketRepo = _FakeSocketRepository();
    final outputCubit = OutputPracticeCubit(
      GetOutputPracticeConversationUseCase(outputRepo),
      GetOutputPracticeConversationUsageUseCase(outputRepo),
      GetAllOutputPracticeMessagesUseCase(outputRepo),
      CreateOutputPracticeConversationUseCase(outputRepo),
      SendOutputPracticeMessageUseCase(outputRepo),
      GetCourseLessonUseCase(_FakeCourseLessonRepository()),
    );
    final socketCubit = OutputPracticeSocketCubit(socketRepo);
    addTearDown(outputCubit.close);
    addTearDown(socketCubit.close);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<OutputPracticeCubit>.value(value: outputCubit),
              BlocProvider<OutputPracticeSocketCubit>.value(value: socketCubit),
            ],
            child: const OutputPracticePage(sectionId: 'section-1'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice'), findsAtLeastNWidgets(1));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Practice'), findsAtLeastNWidgets(1));
  });
}
