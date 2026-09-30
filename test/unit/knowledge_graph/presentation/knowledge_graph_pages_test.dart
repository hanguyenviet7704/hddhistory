import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _FakeStudyThemeRepository extends Fake implements IStudyThemeRepository {
  @override
  TaskEither<AppException, List<StudyThemePreset>> getStudyThemes() =>
      TaskEither.right(const []);
}

/// Trả về đúng dữ liệu mà Neo4j đang giữ cho `ngo_quyen`, để test dựng màn hình
/// trên nội dung thật chứ không phải chuỗi "lorem ipsum" — chiều dài tên tiếng
/// Việt có dấu và mô tả nhiều dòng là thứ làm vỡ bố cục.
class _FakeKgRepository extends Fake implements IKnowledgeGraphRepository {
  static const _ngoQuyen = KgEntitySummary(
    id: 'ngo_quyen',
    type: KgEntityType.figure,
    name: 'Ngô Quyền',
    description:
        'Đánh bại quân Nam Hán trên sông Bạch Đằng năm 938, chấm dứt hơn 1000 '
        'năm Bắc thuộc, xưng vương lập nhà Ngô.',
  );

  static const _tranBachDang = KgEntitySummary(
    id: 'tran_bach_dang_938',
    type: KgEntityType.event,
    name: 'Trận Bạch Đằng năm 938',
    description: 'Ngô Quyền dùng kế cắm cọc đánh bại thủy quân Nam Hán.',
  );

  static const _duongTamKha = KgEntitySummary(
    id: 'duong_tam_kha',
    type: KgEntityType.figure,
    name: 'Dương Tam Kha',
  );

  @override
  TaskEither<AppException, List<KgEntitySummary>> searchEntities({
    required String query,
    int limit = 20,
  }) => TaskEither.right(const [_ngoQuyen, _tranBachDang]);

  @override
  TaskEither<AppException, KgEntityProfile> getEntityProfile(String id) =>
      TaskEither.right(
        const KgEntityProfile(
          id: 'ngo_quyen',
          type: KgEntityType.figure,
          name: 'Ngô Quyền',
          description:
              'Đánh bại quân Nam Hán trên sông Bạch Đằng năm 938, chấm dứt hơn '
              '1000 năm Bắc thuộc, xưng vương lập nhà Ngô.',
          period: KgPeriod(
            id: 'p03_ngo_dinh_tienle',
            name: 'Ngô – Đinh – Tiền Lê',
            start: '939',
            end: '1009',
          ),
          outgoing: [
            KgRelation(relation: 'led', entity: _tranBachDang),
          ],
          incoming: [
            KgRelation(relation: 'succeeded', entity: _duongTamKha),
          ],
          samePeriod: [
            KgEntitySummary(
              id: 'dinh_bo_linh',
              type: KgEntityType.figure,
              name: 'Đinh Bộ Lĩnh',
            ),
          ],
          sources: [
            KgSource(id: 'dvsktt', title: 'Đại Việt sử ký toàn thư'),
          ],
        ),
      );

  @override
  TaskEither<AppException, List<KgRelatedEntity>> getRelatedEntities({
    required String id,
    int maxHops = 2,
    int limit = 20,
  }) => TaskEither.right(const [
    KgRelatedEntity(
      id: 'ngo_xuong_van',
      type: KgEntityType.figure,
      name: 'Ngô Xương Văn',
      hops: 1,
      via: ['child_of'],
    ),
  ]);
}

void main() {
  late KnowledgeGraphCubit cubit;

  setUpAll(() async => setupLocaleCubitForTests(locale: AppLocale.vi));

  setUp(() {
    if (AppDI.injector.isRegistered<StudyThemeCubit>()) {
      AppDI.injector.unregister<StudyThemeCubit>();
    }
    AppDI.injector.registerSingleton<StudyThemeCubit>(
      StudyThemeCubit(GetStudyThemesUseCase(_FakeStudyThemeRepository())),
    );

    final repository = _FakeKgRepository();
    cubit = KnowledgeGraphCubit(
      SearchKgEntitiesUseCase(repository),
      GetKgEntityProfileUseCase(repository),
      GetKgRelatedEntitiesUseCase(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget wrap(Widget page) => ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(home: child),
    ),
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: AppDI.injector.get<StudyThemeCubit>()),
      ],
      child: page,
    ),
  );

  group('KnowledgeGraphSearchPage', () {
    testWidgets('dựng được và hiện kết quả tìm kiếm', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const KnowledgeGraphSearchPage()));
      await tester.pumpAndSettle();

      expect(find.text('Tra cứu lịch sử'), findsOneWidget);
      expect(find.text('Ngô Quyền'), findsOneWidget);
      expect(find.text('Trận Bạch Đằng năm 938'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('KnowledgeGraphProfilePage', () {
    testWidgets('dựng đủ các mục của hồ sơ', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(const KnowledgeGraphProfilePage(entityId: 'ngo_quyen')),
      );
      await tester.pumpAndSettle();

      // Tên + huy hiệu loại + thời kỳ
      expect(find.text('Ngô Quyền'), findsOneWidget);
      expect(find.text('Nhân vật'), findsOneWidget);
      expect(find.text('Ngô – Đinh – Tiền Lê · 939 – 1009'), findsOneWidget);

      // Tiêu đề các mục
      expect(find.text('Đã làm gì'), findsOneWidget);
      expect(find.text('Được nhắc tới'), findsOneWidget);
      expect(find.text('Có liên quan'), findsOneWidget);
      expect(find.text('Cùng thời kỳ'), findsOneWidget);
      expect(find.text('Nguồn sử liệu'), findsOneWidget);

      // Quan hệ đọc ra thành câu, đúng thứ tự nhãn theo chiều
      expect(find.text('lãnh đạo · Trận Bạch Đằng năm 938'), findsOneWidget);
      expect(find.text('Dương Tam Kha · kế vị'), findsOneWidget);

      // Thực thể liên quan kèm số bước và đường đi
      expect(find.text('Ngô Xương Văn'), findsOneWidget);
      expect(find.text('1 bước'), findsOneWidget);
      expect(find.text('là con của'), findsOneWidget);

      expect(find.text('Đại Việt sử ký toàn thư'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
