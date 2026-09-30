import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../../../support/test_di.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockUserCubit extends Mock implements UserCubit {}

/// [OnboardV2Cubit.prewarmHomeData] resolves a real [HomeCubit] from
/// [AppDI.injector] — a `Fake` (not a stubbed `Mock`) lets the one method the
/// cubit actually calls succeed instantly, while anything else touched would
/// throw loudly via [Fake]'s `noSuchMethod` instead of needing a DI graph.
class _FakeHomeCubit extends Fake implements HomeCubit {
  @override
  Future<void> initializeData({bool isInit = false, bool force = false}) async {}
}

class _FakeDeviceInfoService implements IDeviceInfoService {
  @override
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<String> get deviceName async => 'iPhone';

  @override
  Future<String> get deviceToken async => 'device-token';

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

/// `submitAnswers` returns [recommendation] verbatim — enough to drive
/// `_submitAndRecommend`'s success branch without a real backend.
class _FakeOnboardingRepository implements IOnboardingRepository {
  _FakeOnboardingRepository({this.recommendation = const OnboardingRecommendationEntity()});

  final OnboardingRecommendationEntity recommendation;

  @override
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig() => TaskEither.right(const OnboardingContentConfigEntity());

  @override
  TaskEither<AppException, OnboardingTaxonomyEntity> getTaxonomy() => TaskEither.right(const OnboardingTaxonomyEntity());

  @override
  TaskEither<AppException, OnboardingRecommendationEntity> submitAnswers(OnboardingAnswersRequest request) => TaskEither.right(recommendation);
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity());

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) => TaskEither.right(const UserEntity());
}

/// Test-only subclass exposing `seed` so a test can start the cubit from any
/// [OnboardV2State] without replaying every screen that produces it — mirrors
/// the `_SeededOnboardV2Cubit` pattern in onboard_v2_p2_name_test.dart.
class _TestableOnboardV2Cubit extends OnboardV2Cubit {
  _TestableOnboardV2Cubit({OnboardingRecommendationEntity recommendation = const OnboardingRecommendationEntity()})
    : super.forTest(
        GetOnboardingContentConfigUseCase(_FakeOnboardingRepository()),
        UpdateUserUseCase(_FakeProfileRepository()),
        GetOnboardingTaxonomyUseCase(_FakeOnboardingRepository()),
        SubmitOnboardingAnswersUseCase(_FakeOnboardingRepository(recommendation: recommendation)),
        _FakeDeviceInfoService(),
        _MockAuthBloc(),
        _MockUserCubit(),
        AppDI.injector.get<LocaleCubit>(),
        // submitReminder/prewarmHomeData both go through _ensureAnonymousSession
        // — short-circuit it so neither touches the mocked AuthBloc.
        hasActiveAnonymousSession: () => true,
      );

  void seed(OnboardV2State state) => emit(state);
}

OnboardingPackageEntity _pkg(String code, String branch, int order) =>
    OnboardingPackageEntity(code: code, branchCode: branch, order: order);

/// Small fixture — 2 branches, enough packages each for câu 2's round-robin
/// (LV/CX) to be exercised without needing the full 5-branch taxonomy from
/// onboard_v2_selection_rules_test.dart.
OnboardingTaxonomyEntity _taxonomy() => OnboardingTaxonomyEntity(
  branches: const [
    OnboardingBranchEntity(code: 'LV', label: BaseMultiLanguage(vi: 'LV')),
    OnboardingBranchEntity(code: 'CX', label: BaseMultiLanguage(vi: 'CX')),
  ],
  packages: [
    for (var i = 1; i <= 7; i++) _pkg('LV-$i', 'LV', i),
    for (var i = 1; i <= 6; i++) _pkg('CX-$i', 'CX', i),
  ],
);

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  test('toggleBranch giữ đúng THỨ TỰ chọn, và câu 2 round-robin theo đúng thứ tự đó', () {
    final cubit = _TestableOnboardV2Cubit();
    addTearDown(cubit.close);
    cubit.seed(OnboardV2State(taxonomy: _taxonomy(), taxonomyStatus: OnboardV2TaxonomyStatus.success));

    cubit.toggleBranch('LV');
    cubit.toggleBranch('CX');

    expect(cubit.state.selectedBranchCodes, ['LV', 'CX']);
    // 2 nhánh -> round-robin xen kẽ theo thứ tự CHỌN (LV trước, CX sau), y hệt
    // luật của onboard_v2_selection_rules_test.dart.
    expect(cubit.state.problemOptions.map((p) => p.code).take(4), ['LV-1', 'CX-1', 'LV-2', 'CX-2']);

    // Bỏ LV rồi chọn lại (không đụng CX) đẩy LV xuống cuối thứ tự chọn — round
    // robin phải đảo theo, KHÔNG giữ thứ tự cũ.
    cubit.toggleBranch('LV');
    cubit.toggleBranch('LV');
    expect(cubit.state.selectedBranchCodes, ['CX', 'LV']);
    expect(cubit.state.problemOptions.map((p) => p.code).take(2), ['CX-1', 'LV-1']);
  });

  test('bỏ chọn 1 nhánh cắt các gói của nhánh đó và xoá mong muốn nếu không còn hợp lệ', () {
    final cubit = _TestableOnboardV2Cubit();
    addTearDown(cubit.close);
    cubit.seed(OnboardV2State(taxonomy: _taxonomy(), taxonomyStatus: OnboardV2TaxonomyStatus.success));

    cubit.toggleBranch('LV');
    cubit.toggleBranch('CX');
    cubit.togglePackage('LV-1');
    cubit.togglePackage('CX-1');
    cubit.selectDesire('CX-1');
    expect(cubit.state.selectedPackageCodes, ['LV-1', 'CX-1']);
    expect(cubit.state.selectedDesireCode, 'CX-1');

    // Bỏ chọn CX: gói CX-1 phải bị cắt khỏi selectedPackageCodes, và mong
    // muốn CX-1 (không còn trong desireOptions chỉ-còn-LV) phải bị xoá.
    cubit.toggleBranch('CX');

    expect(cubit.state.selectedBranchCodes, ['LV']);
    expect(cubit.state.selectedPackageCodes, ['LV-1']);
    expect(cubit.state.selectedDesireCode, isNull);
  });

  test('submitReminder chuyển p9Loading ngay lập tức, rồi recommendStatus thành loaded khi submit trả khoá', () async {
    const course = CourseEntity(id: 'course_1');
    final cubit = _TestableOnboardV2Cubit(recommendation: const OnboardingRecommendationEntity(courses: [course]));
    addTearDown(cubit.close);
    // prewarmHomeData (fire-and-forget bên trong submitReminder) resolves a
    // real HomeCubit off AppDI — stand one in so that unawaited call succeeds
    // instead of throwing "not registered".
    AppDI.injector.registerSingleton<HomeCubit>(_FakeHomeCubit());
    cubit.seed(const OnboardV2State(currentPage: OnboardV2PageStep.p8Reminder));

    final future = cubit.submitReminder(enabled: false, notificationStatus: OnboardV2NotificationStatus.maybeLater);
    // emit(currentPage: p9Loading) happens synchronously before the first
    // real await inside submitReminder, so this is already true here.
    expect(cubit.state.currentPage, OnboardV2PageStep.p9Loading);
    expect(cubit.state.recommendStatus, OnboardV2RecommendStatus.loading);

    await future;
    await cubit.prewarmHomeData(); // drain the memoised prewarm before teardown resets DI.

    expect(cubit.state.recommendStatus, OnboardV2RecommendStatus.loaded);
    expect(cubit.state.recommendedCourses, [course]);
  });
}
