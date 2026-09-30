# Onboarding v3 — hddhistory-flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng lại luồng `onboard_v2` theo design 12 màn: 3 câu hỏi phụ thuộc lấy từ `GET /onboarding-taxonomy`, nhắc học có giờ, loading + 3 card kết quả từ `POST /onboarding-answers`, rồi theme → Home.

**Architecture:** Giữ khung `lib/src/onboard_v2/` (PageView + `OnboardV2Cubit` + `OnboardV2ScreenShell`), thay các trang path/symptom/notification/course-picker bằng trang mới; dữ liệu mới nằm trong `lib/src/onboarding/` (Retrofit + repository + use case, freezed). Luật câu 2/3 là helper thuần có unit test. Enum `OnboardingPath/OnboardingSymptom` KHÔNG còn dùng trong onboarding (giữ trong `course_model.dart` vì CourseModel còn decode).

**Tech Stack:** Flutter, freezed/json_serializable/injectable/retrofit (build_runner), fpdart TaskEither, slang l10n (5 locale), flutter_screenutil (`.w/.h/.r`).

**Spec:** `hddhistory-api/plans/260918-onboarding-v3-taxonomy/design.md` (§3, §6). API contract: `plan-api.md` Task 2/5/7.

## Global Constraints

- `flutter`/`dart` không có trong PATH: dùng `/Users/nguyenvietha/development/flutter/bin/flutter` và `/Users/nguyenvietha/development/flutter/bin/dart`; `cd` absolute trong CÙNG lệnh.
- Codegen: `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/dart run build_runner build --delete-conflicting-outputs` rồi `dart run slang`. Lời than "Asset already exists" về `l10n.g.dart` là nhiễu; kiểm "wrote N outputs". KHÔNG sửa `*.g.dart`/`*.freezed.dart`/`*.config.dart`.
- Gate: `flutter analyze` (KHÔNG `flutter test` toàn bộ — chỉ chạy đúng 1 file test).
- Cây làm việc dơ (35 file WIP của phiên khác): **không** `git checkout --`/`git stash`/`git add <dir>`; `git add` đúng file; không `dart format` cả cây.
- `AppText` mặc định `maxLines: 10` + ellipsis; nội dung dài dùng `maxLines: 100` hoặc `overflow: TextOverflow.visible`.
- l10n: sửa YAML `assets/i18n/<locale>/onboarding.yaml` cho ĐỦ 5 locale (en, vi, zh, ja, ko), rồi `dart run slang`.
- Commit `type: <tiếng Việt>` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, thẳng `develop`.
- Cubit đi qua `runUseCase*` mixin hoặc `.run()` + `fold` như code hiện có; widget không giữ dữ liệu fetch.

---

## File map

```
lib/core/constants/manual/endpoint.dart                       (+ onboardingTaxonomy, onboardingAnswers)
lib/core/constants/manual/tracking_key.dart                   (+ onboardV2P10View, onboardV2P11View, onboardV2ReminderTimeSelect)
lib/src/onboarding/                                           (data layer)
  data/models/onboarding_taxonomy_model.dart                  (mới: branch/package/tree)
  data/models/onboarding_recommendation_model.dart            (mới: answers + recommended course)
  data/models/onboarding_desire_config_model.dart, onboarding_how_config_model.dart,
  data/models/onboarding_reminder_config_model.dart, onboarding_loading_config_model.dart (mới)
  data/models/onboarding_content_config_model.dart            (+4 section)
  data/datasources/remote/onboarding_api.dart                 (+2 route)
  data/datasources/local/onboarding_local_data_source.dart    (+cache taxonomy)
  data/repositories/onboarding_repository.dart                (+2 method)
  domain/entities/onboarding_taxonomy_entity.dart, onboarding_recommendation_entity.dart (mới)
  domain/entities/onboarding_{desire,how,reminder,loading}_config_entity.dart (mới)
  domain/entities/onboarding_content_config_entity.dart       (+4 section)
  domain/repositories/i_onboarding_repository.dart            (+2)
  domain/usecases/get_onboarding_taxonomy_usecase.dart, submit_onboarding_answers_usecase.dart (mới)
  onboarding.dart                                             (parts)
lib/src/onboard_v2/
  presentation/helpers/onboard_v2_selection_rules.dart        (mới, thuần)
  presentation/helpers/onboard_v2_config_mapper.dart          (bỏ paths/symptoms, +copy mới)
  presentation/helpers/onboard_v2_tracking_helper.dart        (page names mới, params theo mã)
  presentation/cubits/onboard_v2_state.dart, onboard_v2_cubit.dart
  presentation/pages/onboard_v2_page.dart                     (11 trang)
  presentation/pages/onboard_v2_branch_page.dart, onboard_v2_problem_page.dart, onboard_v2_desire_page.dart,
  presentation/pages/onboard_v2_how_page.dart, onboard_v2_reminder_page.dart, onboard_v2_loading_page.dart,
  presentation/pages/onboard_v2_result_page.dart              (mới; result tái dùng carousel của course_picker)
  presentation/pages/onboard_v2_age_page.dart                 (grid 2 cột)
  presentation/pages/onboard_v2_pick_theme_page.dart          (→ Home)
  presentation/widgets/p8/onboard_v2_time_wheel.dart          (mới: hh:mm bước 15)
  presentation/widgets/shared/onboard_v2_selectable_option_row.dart (+subtitle)
  presentation/widgets/shared/onboard_v2_chip.dart            (mới)
  onboard_v2.dart                                             (parts)
  XOÁ: pages/onboard_v2_path_map_page.dart, onboard_v2_path_selection_page.dart, onboard_v2_symptom_selection_page.dart,
       onboard_v2_notification_page.dart, onboard_v2_course_picker_page.dart (nội dung chuyển sang result), widgets/p6/onboard_v2_path_map*.dart (4 file),
       helpers/onboard_v2_path_resolver.dart, onboard_v2_symptom_selection_mapper.dart, onboard_v2_random_course_picker.dart,
       data/*, domain/* của onboard_v2 (scaffold chết), onboard_v2.g.dart nếu không còn json
lib/src/auth/presentation/cubits/user_state.dart, user_cubit.dart   (onboardingSkillsetOrder)
lib/src/home/presentation/cubits/home_state.dart                    (xếp theo skillsetId)
assets/i18n/{en,vi,zh,ja,ko}/onboarding.yaml
test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart (mới)
```

---

### Task 1: Data layer — taxonomy, answers/recommendation, 4 section config mới

**Files:** xem File map mục `lib/src/onboarding/` + `endpoint.dart`.

**Interfaces — Produces:**
```dart
OnboardingBranchEntity { code, label: BaseMultiLanguage, subtitle: BaseMultiLanguage, iconUrl, imageUrl, order, isSelectable, skillsetId (String?), isActive }
OnboardingPackageEntity { code, branchCode, problemLabel, desireLabel, order, isActive }
OnboardingTaxonomyEntity { branches: List<OnboardingBranchEntity>, packages: List<OnboardingPackageEntity> }
OnboardingAnswersRequest { branchCodes?, packageCodes?, desireCode?, reminderEnabled?, reminderTime?, chosenCourseId?, ageKey?, completed? }  // toJson bỏ null
OnboardingRecommendationEntity { courses: List<CourseEntity>, matchReasons: Map<courseId, OnboardingMatchReasonEntity> }
OnboardingMatchReasonEntity { desire: bool, labelCodes: List<String>, packageCodes: List<String> }
IOnboardingRepository.getTaxonomy(): TaskEither<AppException, OnboardingTaxonomyEntity>          // Left khi lỗi & không có cache
IOnboardingRepository.submitAnswers(OnboardingAnswersRequest): TaskEither<AppException, OnboardingRecommendationEntity>
GetOnboardingTaxonomyUseCase(unit), SubmitOnboardingAnswersUseCase(request)
OnboardingContentConfigEntity.desire/how/reminder/loading (xem plan-api Task 7 cho field)
AppEndpoint.onboardingTaxonomy = '/api/v1/onboarding-taxonomy'; AppEndpoint.onboardingAnswers = '/api/v1/onboarding-answers'
```

- [ ] **Step 1: Endpoint + entities**

```dart
// endpoint.dart — sau onboardingContentConfig
//* Onboarding v3 (taxonomy trong DB + câu trả lời + gợi ý khoá)
static const String onboardingTaxonomy = '/api/v1/onboarding-taxonomy';
static const String onboardingAnswers = '/api/v1/onboarding-answers';
```
```dart
// lib/src/onboarding/domain/entities/onboarding_taxonomy_entity.dart
part of '../../onboarding.dart';

@freezed
abstract class OnboardingBranchEntity with _$OnboardingBranchEntity {
  const factory OnboardingBranchEntity({
    @Default('') String code,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default('') String iconUrl,
    @Default('') String imageUrl,
    @Default(0) int order,
    @Default(true) bool isSelectable,
    String? skillsetId,
    @Default(true) bool isActive,
  }) = _OnboardingBranchEntity;
}

@freezed
abstract class OnboardingPackageEntity with _$OnboardingPackageEntity {
  const factory OnboardingPackageEntity({
    @Default('') String code,
    @Default('') String branchCode,
    @Default(BaseMultiLanguage()) BaseMultiLanguage problemLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage desireLabel,
    @Default(0) int order,
    @Default(true) bool isActive,
  }) = _OnboardingPackageEntity;
}

@freezed
abstract class OnboardingTaxonomyEntity with _$OnboardingTaxonomyEntity {
  const factory OnboardingTaxonomyEntity({
    @Default([]) List<OnboardingBranchEntity> branches,
    @Default([]) List<OnboardingPackageEntity> packages,
  }) = _OnboardingTaxonomyEntity;
}

extension OnboardingTaxonomyEntityX on OnboardingTaxonomyEntity {
  bool get isEmpty => branches.isEmpty || packages.isEmpty;
  List<OnboardingBranchEntity> get selectableBranches =>
      [...branches.where((b) => b.isSelectable && b.isActive)]..sort((a, b) => a.order.compareTo(b.order));
  List<OnboardingPackageEntity> packagesOf(String branchCode) =>
      [...packages.where((p) => p.branchCode == branchCode && p.isActive)]..sort((a, b) => a.order.compareTo(b.order));
  OnboardingPackageEntity? packageByCode(String code) => packages.cast<OnboardingPackageEntity?>().firstWhere((p) => p!.code == code, orElse: () => null);
  OnboardingBranchEntity? branchByCode(String code) => branches.cast<OnboardingBranchEntity?>().firstWhere((b) => b!.code == code, orElse: () => null);
}
```
```dart
// lib/src/onboarding/domain/entities/onboarding_recommendation_entity.dart
part of '../../onboarding.dart';

@freezed
abstract class OnboardingMatchReasonEntity with _$OnboardingMatchReasonEntity {
  const factory OnboardingMatchReasonEntity({
    @Default(false) bool desire,
    @Default([]) List<String> labelCodes,
    @Default([]) List<String> packageCodes,
  }) = _OnboardingMatchReasonEntity;
}

@freezed
abstract class OnboardingRecommendationEntity with _$OnboardingRecommendationEntity {
  const factory OnboardingRecommendationEntity({
    @Default([]) List<CourseEntity> courses,
    @Default({}) Map<String, OnboardingMatchReasonEntity> matchReasons,
  }) = _OnboardingRecommendationEntity;
}

/// Body của POST /onboarding-answers. Mọi field optional; null không gửi.
class OnboardingAnswersRequest {
  const OnboardingAnswersRequest({
    this.branchCodes, this.packageCodes, this.desireCode, this.reminderEnabled,
    this.reminderTime, this.chosenCourseId, this.ageKey, this.completed,
  });
  final List<String>? branchCodes;
  final List<String>? packageCodes;
  final String? desireCode;
  final bool? reminderEnabled;
  final String? reminderTime;
  final String? chosenCourseId;
  final String? ageKey;
  final bool? completed;

  Map<String, dynamic> toJson() => {
    if (branchCodes != null) 'branchCodes': branchCodes,
    if (packageCodes != null) 'packageCodes': packageCodes,
    if (desireCode != null) 'desireCode': desireCode,
    if (reminderEnabled != null) 'reminderEnabled': reminderEnabled,
    if (reminderTime != null) 'reminderTime': reminderTime,
    if (chosenCourseId != null) 'chosenCourseId': chosenCourseId,
    if (ageKey != null) 'ageKey': ageKey,
    if (completed != null) 'completed': completed,
  };
}
```
4 entity config mới (mỗi file 1 `@freezed`, mọi field `@Default(BaseMultiLanguage())`; `how.steps: List<OnboardingHowStepEntity{title, body}>`, `reminder.presets: List<OnboardingReminderPresetEntity{label, time: String}>`, `loading.lines: List<BaseMultiLanguage>`). Thêm 4 field vào `OnboardingContentConfigEntity` với `@Default(...)`.

- [ ] **Step 2: Models (json) + API + repo + use cases**

```dart
// data/models/onboarding_taxonomy_model.dart — mirror entity với fromJson; toEntity()
@freezed
abstract class OnboardingBranchModel with _$OnboardingBranchModel {
  const factory OnboardingBranchModel({
    @Default('') String code,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default('') String iconUrl,
    @Default('') String imageUrl,
    @Default(0) int order,
    @Default(true) bool isSelectable,
    String? skillsetId,
    @Default(true) bool isActive,
  }) = _OnboardingBranchModel;
  factory OnboardingBranchModel.fromJson(Map<String, dynamic> json) => _$OnboardingBranchModelFromJson(json);
}
// OnboardingPackageModel, OnboardingTaxonomyModel { branches, packages } tương tự + extension toEntity().

// data/models/onboarding_recommendation_model.dart
@freezed
abstract class OnboardingMatchReasonModel with _$OnboardingMatchReasonModel { ... desire, labelCodes, packageCodes ... }

@freezed
abstract class OnboardingRecommendedCourseModel with _$OnboardingRecommendedCourseModel {
  const factory OnboardingRecommendedCourseModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
    @Default(OnboardingMatchReasonModel()) OnboardingMatchReasonModel matchReason,
  }) = _OnboardingRecommendedCourseModel;
  factory OnboardingRecommendedCourseModel.fromJson(Map<String, dynamic> json) => _$OnboardingRecommendedCourseModelFromJson(json);
}

@freezed
abstract class OnboardingRecommendationModel with _$OnboardingRecommendationModel {
  const factory OnboardingRecommendationModel({
    @Default([]) List<OnboardingRecommendedCourseModel> recommendations,
  }) = _OnboardingRecommendationModel;
  factory OnboardingRecommendationModel.fromJson(Map<String, dynamic> json) => _$OnboardingRecommendationModelFromJson(json);
}

extension OnboardingRecommendationModelX on OnboardingRecommendationModel {
  OnboardingRecommendationEntity toEntity() => OnboardingRecommendationEntity(
    courses: [
      for (final c in recommendations)
        CourseEntity(id: c.id, title: c.title, description: c.description, image: c.image, skillsetId: c.skillsetId, numberOfLesson: c.numberOfLesson),
    ],
    matchReasons: {for (final c in recommendations) c.id: OnboardingMatchReasonEntity(desire: c.matchReason.desire, labelCodes: c.matchReason.labelCodes, packageCodes: c.matchReason.packageCodes)},
  );
}
```
```dart
// onboarding_api.dart — thêm
@GET(AppEndpoint.onboardingTaxonomy)
Future<BaseResponse<OnboardingTaxonomyModel>> getTaxonomy();

@POST(AppEndpoint.onboardingAnswers)
Future<BaseResponse<OnboardingRecommendationModel>> submitAnswers(@Body() Map<String, dynamic> body);
```
```dart
// onboarding_local_data_source.dart — thêm cache taxonomy (key 'onboarding_taxonomy_cache'): getCachedTaxonomy()/cacheTaxonomy(model), cùng try/catch.

// onboarding_repository.dart — thêm
/// Khác config: KHÔNG có fallback enum nữa. Lỗi mạng → cache; không có cache
/// → Left để S4 hiện lỗi + Thử lại (không có gì để hiển thị nếu thiếu nhánh).
@override
TaskEither<AppException, OnboardingTaxonomyEntity> getTaxonomy() {
  return callApiWithTransform<OnboardingTaxonomyModel, OnboardingTaxonomyEntity>(
    apiCall: () => _api.getTaxonomy(),
    transform: (model) => model.toEntity(),
    onSuccess: (data) async { if (data != null) await _localDataSource.cacheTaxonomy(data); },
    onError: () async {
      final cached = await _localDataSource.getCachedTaxonomy();
      return cached?.toEntity();
    },
    enableErrorMessages: false,
  );
}

@override
TaskEither<AppException, OnboardingRecommendationEntity> submitAnswers(OnboardingAnswersRequest request) {
  return callApiWithTransform<OnboardingRecommendationModel, OnboardingRecommendationEntity>(
    apiCall: () => _api.submitAnswers(request.toJson()),
    transform: (model) => model.toEntity(),
    enableErrorMessages: false,
  );
}
```
Đọc `callApiWithTransform` (lib/core/base/network/restful_request.dart:128) để chắc `onError` trả null → Left (nếu helper coi null là lỗi). Nếu không, bọc `TaskEither` thủ công.
Use case: `GetOnboardingTaxonomyUseCase implements BaseUseCase<Unit, OnboardingTaxonomyEntity>`, `SubmitOnboardingAnswersUseCase implements BaseUseCase<OnboardingAnswersRequest, OnboardingRecommendationEntity>` (`@lazySingleton`, khuôn `GetOnboardingContentConfigUseCase`).
Thêm `part` cho mọi file mới vào `lib/src/onboarding/onboarding.dart`. Cần import `lib/src/course` (CourseEntity) — barrel `package:hddhistory/hddhistory.dart` đã gom, kiểm tra không vòng import.

- [ ] **Step 3: Codegen + analyze + commit**

Run: `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5` → "wrote N outputs". `/Users/nguyenvietha/development/flutter/bin/flutter analyze lib/src/onboarding` → No issues.
```bash
git add lib/core/constants/manual/endpoint.dart lib/src/onboarding/onboarding.dart lib/src/onboarding/onboarding.freezed.dart lib/src/onboarding/onboarding.g.dart lib/src/onboarding/data/models/onboarding_taxonomy_model.dart lib/src/onboarding/data/models/onboarding_recommendation_model.dart lib/src/onboarding/data/models/onboarding_desire_config_model.dart lib/src/onboarding/data/models/onboarding_how_config_model.dart lib/src/onboarding/data/models/onboarding_reminder_config_model.dart lib/src/onboarding/data/models/onboarding_loading_config_model.dart lib/src/onboarding/data/models/onboarding_content_config_model.dart lib/src/onboarding/data/datasources/remote/onboarding_api.dart lib/src/onboarding/data/datasources/local/onboarding_local_data_source.dart lib/src/onboarding/data/repositories/onboarding_repository.dart lib/src/onboarding/domain/entities/onboarding_taxonomy_entity.dart lib/src/onboarding/domain/entities/onboarding_recommendation_entity.dart lib/src/onboarding/domain/entities/onboarding_desire_config_entity.dart lib/src/onboarding/domain/entities/onboarding_how_config_entity.dart lib/src/onboarding/domain/entities/onboarding_reminder_config_entity.dart lib/src/onboarding/domain/entities/onboarding_loading_config_entity.dart lib/src/onboarding/domain/entities/onboarding_content_config_entity.dart lib/src/onboarding/domain/repositories/i_onboarding_repository.dart lib/src/onboarding/domain/usecases/get_onboarding_taxonomy_usecase.dart lib/src/onboarding/domain/usecases/submit_onboarding_answers_usecase.dart lib/config/di/injection.config.dart
git commit -m "feat: tầng dữ liệu onboarding v3 — taxonomy, gửi câu trả lời, 4 section config mới" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(Kiểm đường dẫn file `injection.config.dart` thật bằng `git status --short | grep config.dart` — chỉ add nếu nó đổi vì use case mới.)

---

### Task 2: Luật câu 2 / câu 3 — helper thuần + unit test

**Files:**
- Create: `lib/src/onboard_v2/presentation/helpers/onboard_v2_selection_rules.dart` (part of onboard_v2.dart)
- Create: `test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart`

**Produces:**
```dart
abstract final class OnboardV2SelectionRules {
  static const int maxProblemOptions = 10;
  static List<OnboardingPackageEntity> problemOptions(OnboardingTaxonomyEntity taxonomy, List<String> branchCodesInSelectionOrder);
  static List<OnboardingPackageEntity> desireOptions(OnboardingTaxonomyEntity taxonomy, List<String> packageCodesInSelectionOrder, {required int seed});
  static int seedFor(List<String> packageCodes);   // ổn định theo bộ gói
}
```

- [ ] **Step 1: Test thất bại**

```dart
// test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

OnboardingPackageEntity pkg(String code, String branch, int order) => OnboardingPackageEntity(
  code: code, branchCode: branch, order: order,
  problemLabel: BaseMultiLanguage(vi: 'p $code'), desireLabel: BaseMultiLanguage(vi: 'd $code'),
);

OnboardingTaxonomyEntity taxonomy() => OnboardingTaxonomyEntity(
  branches: [
    for (final b in ['CX', 'LV', 'TD', 'QH', 'HT']) OnboardingBranchEntity(code: b, label: BaseMultiLanguage(vi: b)),
  ],
  packages: [
    for (var i = 1; i <= 6; i++) pkg('CX-$i', 'CX', i),
    for (var i = 1; i <= 7; i++) pkg('LV-$i', 'LV', i),
    for (var i = 1; i <= 3; i++) pkg('TD-$i', 'TD', i),
    for (var i = 1; i <= 5; i++) pkg('QH-$i', 'QH', i),
    for (var i = 1; i <= 5; i++) pkg('HT-$i', 'HT', i),
  ],
);

List<String> codes(List<OnboardingPackageEntity> list) => list.map((p) => p.code).toList();
int countPrefix(List<OnboardingPackageEntity> list, String prefix) => list.where((p) => p.branchCode == prefix).length;

void main() {
  group('problemOptions (câu 2)', () {
    test('1 nhánh → toàn bộ gói của nhánh, theo order', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['LV']);
      expect(codes(r), ['LV-1', 'LV-2', 'LV-3', 'LV-4', 'LV-5', 'LV-6', 'LV-7']);
    });

    test('2 nhánh → 5/5, xen kẽ theo thứ tự chọn', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['LV', 'CX']);
      expect(r.length, 10);
      expect(countPrefix(r, 'LV'), 5);
      expect(countPrefix(r, 'CX'), 5);
      expect(codes(r).take(2), ['LV-1', 'CX-1']);
    });

    test('3 nhánh → 4/3/3', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'QH']);
      expect([countPrefix(r, 'CX'), countPrefix(r, 'LV'), countPrefix(r, 'QH')], [4, 3, 3]);
    });

    test('4 nhánh → 3/3/2/2; 5 nhánh → 2 mỗi nhánh', () {
      final r4 = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'QH', 'HT']);
      expect([countPrefix(r4, 'CX'), countPrefix(r4, 'LV'), countPrefix(r4, 'QH'), countPrefix(r4, 'HT')], [3, 3, 2, 2]);
      final r5 = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'TD', 'QH', 'HT']);
      expect(r5.length, 10);
      expect(['CX', 'LV', 'TD', 'QH', 'HT'].map((b) => countPrefix(r5, b)), everyElement(2));
    });

    test('nhánh ít gói (TD có 3) thì nhánh khác lấp cho đủ 10', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['TD', 'LV']);
      expect(r.length, 10);
      expect(countPrefix(r, 'TD'), 3);
      expect(countPrefix(r, 'LV'), 7);
    });

    test('không chọn nhánh → rỗng', () {
      expect(OnboardV2SelectionRules.problemOptions(taxonomy(), []), isEmpty);
    });
  });

  group('desireOptions (câu 3)', () {
    test('1 gói → mọi mong muốn cùng nhánh', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['CX-2'], seed: 1);
      expect(codes(r), ['CX-1', 'CX-2', 'CX-3', 'CX-4', 'CX-5', 'CX-6']);
    });

    test('2 gói → 2 tương ứng + 1 random cùng nhánh cho mỗi gói (≤4), ổn định theo seed', () {
      final a = OnboardV2SelectionRules.desireOptions(taxonomy(), ['LV-1', 'CX-2'], seed: 7);
      final b = OnboardV2SelectionRules.desireOptions(taxonomy(), ['LV-1', 'CX-2'], seed: 7);
      expect(codes(a), codes(b));
      expect(a.length, 4);
      expect(codes(a).take(2), ['LV-1', 'CX-2']);
      expect(a[2].branchCode, 'LV');
      expect(a[3].branchCode, 'CX');
      expect(a[2].code, isNot('LV-1'));
      expect(a[3].code, isNot('CX-2'));
    });

    test('2 gói cùng nhánh → random không trùng nhau và không trùng gói đã chọn', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['TD-1', 'TD-2'], seed: 3);
      expect(codes(r).toSet().length, r.length);
      expect(r.length, 3); // TD chỉ còn TD-3 để random
    });

    test('≥3 gói → chỉ các mong muốn tương ứng, giữ thứ tự chọn', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['HT-2', 'LV-1', 'CX-6'], seed: 1);
      expect(codes(r), ['HT-2', 'LV-1', 'CX-6']);
    });
  });

  test('seedFor không phụ thuộc thứ tự và ổn định', () {
    expect(OnboardV2SelectionRules.seedFor(['A', 'B']), OnboardV2SelectionRules.seedFor(['B', 'A']));
    expect(OnboardV2SelectionRules.seedFor(['A', 'B']), isNot(OnboardV2SelectionRules.seedFor(['A', 'C'])));
  });
}
```

- [ ] **Step 2: Chạy → FAIL** — `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/flutter test test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart` (1 file, được phép).

- [ ] **Step 3: Helper**

```dart
// lib/src/onboard_v2/presentation/helpers/onboard_v2_selection_rules.dart
part of '../../onboard_v2.dart';

/// Luật hiển thị câu 2 / câu 3 (design.md §3.2, §3.3). Thuần, không state.
abstract final class OnboardV2SelectionRules {
  static const int maxProblemOptions = 10;

  /// Câu 2: round-robin theo THỨ TỰ user chọn nhánh, mỗi nhánh lấy gói theo
  /// `order`, dừng ở 10. Cho ra đúng bảng 1→all, 2→5/5, 3→4/3/3, 4→3/3/2/2,
  /// 5→2×5; nhánh hết gói sớm thì nhánh khác lấp.
  static List<OnboardingPackageEntity> problemOptions(
    OnboardingTaxonomyEntity taxonomy,
    List<String> branchCodesInSelectionOrder,
  ) {
    if (branchCodesInSelectionOrder.isEmpty) return const [];
    final queues = [for (final code in branchCodesInSelectionOrder) taxonomy.packagesOf(code)];
    final cap = branchCodesInSelectionOrder.length == 1 ? queues.first.length : maxProblemOptions;
    final out = <OnboardingPackageEntity>[];
    var index = 0;
    while (out.length < cap && queues.any((q) => index < q.length)) {
      for (final q in queues) {
        if (out.length >= cap) break;
        if (index < q.length) out.add(q[index]);
      }
      index++;
    }
    return out;
  }

  /// Câu 3. n=1: mọi mong muốn cùng nhánh. n=2: 2 tương ứng + với mỗi gói 1
  /// random cùng nhánh (không trùng). n≥3: chỉ các mong muốn tương ứng.
  static List<OnboardingPackageEntity> desireOptions(
    OnboardingTaxonomyEntity taxonomy,
    List<String> packageCodesInSelectionOrder,
    {required int seed},
  ) {
    final selected = [
      for (final code in packageCodesInSelectionOrder)
        if (taxonomy.packageByCode(code) case final p?) p,
    ];
    if (selected.isEmpty) return const [];

    if (selected.length == 1) {
      return taxonomy.packagesOf(selected.first.branchCode);
    }
    if (selected.length >= 3) return selected;

    final random = math.Random(seed);
    final out = [...selected];
    final taken = {for (final p in selected) p.code};
    for (final p in selected) {
      final pool = taxonomy.packagesOf(p.branchCode).where((x) => !taken.contains(x.code)).toList();
      if (pool.isEmpty) continue;
      final pick = pool[random.nextInt(pool.length)];
      taken.add(pick.code);
      out.add(pick);
    }
    return out;
  }

  /// Seed ổn định theo BỘ gói (không theo thứ tự) để quay lại màn không xáo.
  static int seedFor(List<String> packageCodes) {
    final sorted = [...packageCodes]..sort();
    return sorted.join('|').hashCode;
  }
}
```
`math` đã import trong `onboard_v2.dart` (`import 'dart:math' as math;`). Thêm `part 'presentation/helpers/onboard_v2_selection_rules.dart';` vào barrel.

- [ ] **Step 4: Chạy test → PASS; `flutter analyze lib/src/onboard_v2`; commit**

```bash
git add lib/src/onboard_v2/onboard_v2.dart lib/src/onboard_v2/presentation/helpers/onboard_v2_selection_rules.dart test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart
git commit -m "feat: luật lọc đáp án câu 2/câu 3 onboarding (round-robin 10 gói, mong muốn theo gói)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: State + Cubit + tracking theo luồng mới

**Files:**
- Modify: `lib/src/onboard_v2/presentation/cubits/onboard_v2_state.dart`
- Modify: `lib/src/onboard_v2/presentation/cubits/onboard_v2_cubit.dart`
- Modify: `lib/src/onboard_v2/presentation/helpers/onboard_v2_tracking_helper.dart`
- Modify: `lib/src/onboard_v2/presentation/helpers/onboard_v2_config_mapper.dart` (bỏ `_mapPaths`/`_enumSymptomsFor`, thêm copy key mới)
- Modify: `lib/core/constants/manual/tracking_key.dart` (+3 hằng)
- Delete: `presentation/helpers/onboard_v2_path_resolver.dart`, `onboard_v2_symptom_selection_mapper.dart`, `onboard_v2_random_course_picker.dart` (+ bỏ `part`)

**Produces (state):**
```dart
enum OnboardV2PageStep { p1Intro, p2Name, p3Age, p4Branches, p5Problems, p6Desire, p7How, p8Reminder, p9Loading, p10Result, p11Theme }
enum OnboardV2TaxonomyStatus { initial, loading, success, failure }
enum OnboardV2RecommendStatus { initial, loading, loaded, fallback }
// fields mới:
OnboardingTaxonomyEntity taxonomy; OnboardV2TaxonomyStatus taxonomyStatus; String? taxonomyErrorMessage;
List<String> selectedBranchCodes; List<String> selectedPackageCodes; String? selectedDesireCode;
List<OnboardingPackageEntity> problemOptions; List<OnboardingPackageEntity> desireOptions;
String reminderTime ('21:00'); bool reminderEnabled (false); OnboardV2NotificationStatus notificationStatus;
List<OnboardingReminderPresetEntity> reminderPresets;   // từ config.reminder.presets; rỗng → trang dùng 3 preset l10n mặc định 07:00/12:30/21:00
OnboardV2RecommendStatus recommendStatus; List<CourseEntity> recommendedCourses; Map<String, OnboardingMatchReasonEntity> matchReasons; int currentCourseIndex; String? recommendErrorMessage;
CourseEntity? chosenCourse; DateTime? loadingStartedAt;
// bỏ: selectedPaths, availableSymptoms, selectedSymptoms, courseStatus, courseErrorMessage, pendingHandoffCourse, pendingHandoffIsBrowse
// getters: canContinueBranches, canContinueProblems, canContinueDesire, currentCourse, hasRecommendedCourses, selectedSkillsetIds (map branch→skillsetId, bỏ null)
```
**Produces (cubit):**
```dart
Future<void> initialize();            // reset + anonymous session + loadOnboardData() + loadTaxonomy()
Future<void> loadTaxonomy();
void toggleBranch(String code);       // giữ thứ tự chọn, tính lại problemOptions, prune selectedPackageCodes, tính lại desireOptions, reset desire nếu không còn
void continueFromP4Branches();        // → p5Problems
void togglePackage(String code);      // guard code ∈ problemOptions; giữ thứ tự; tính lại desireOptions; reset desire nếu không còn
void continueFromP5Problems();        // → p6Desire
void selectDesire(String code);
void continueFromP6Desire();          // → p7How
void continueFromP7How();             // → p8Reminder
void setReminderTime(String hhmm);
Future<void> submitReminder({required bool enabled, required OnboardV2NotificationStatus notificationStatus}); // → p9Loading, gọi submitAnswers
Future<void> retryRecommendation();
void setCurrentCourseIndex(int i);
void goToThemeWithCourse(CourseEntity course);   // POST chosenCourseId+completed (fire-and-forget), → p11Theme
void goToThemeWithoutCourse();                   // completed=true, → p11Theme
Future<void> markUserOnboarded();                // giữ nguyên
Future<void> prewarmHomeData();                  // giữ nguyên
void goBack();                                   // chặn ở p9Loading, p10Result; p8→p7, p5→p4 …
```

- [ ] **Step 1: State** — viết lại file theo khối trên (giữ `onboardStatus/p3SubmitStatus/onboardData/showPaywallAfterOnboarding/name/selectedAge/navigationStatus/onboardErrorMessage/p3ErrorMessage/navigationErrorMessage`). `selectedSkillsetIds`:
```dart
List<String> get selectedSkillsetIds => [
  for (final code in selectedBranchCodes)
    if (taxonomy.branchByCode(code)?.skillsetId case final id? when id.isNotEmpty) id,
];
```

- [ ] **Step 2: Cubit** — thay constructor deps: bỏ `_getAllCoursesUseCase`, `_random`; thêm `GetOnboardingTaxonomyUseCase _getTaxonomyUseCase`, `SubmitOnboardingAnswersUseCase _submitAnswersUseCase`. Sửa `OnboardV2Cubit.withRandom` → `OnboardV2Cubit.forTest` (bỏ Random). Field mới: `int _recommendSerial = 0;` (thay `_courseSerial`), `_invalidateRecommendation() { _recommendSerial += 1; }`. `initialize()` gọi thêm `loadTaxonomy()` song song với `loadOnboardData()` (`await Future.wait([...])`). Trong `loadOnboardData` nhánh success emit thêm `reminderPresets: config.reminder.presets`. `setReminderTime(String hhmm)` = guard regex `^([01]\d|2[0-3]):(00|15|30|45)$` rồi emit + track `TrackingKey.onboardV2ReminderTimeSelect {reminder_time}`. Các method chính:

```dart
Future<void> loadTaxonomy() async {
  final serial = _requestSerial;
  emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.loading, taxonomyErrorMessage: null));
  final result = await _getTaxonomyUseCase(unit).run();
  if (serial != _requestSerial) return;
  result.fold(
    (failure) => emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.failure, taxonomyErrorMessage: failure.displayMessage)),
    (taxonomy) {
      if (taxonomy.isEmpty) {
        emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.failure, taxonomyErrorMessage: l10n.onboarding.onboardingV3TaxonomyLoadError));
        return;
      }
      emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.success, taxonomy: taxonomy));
      _recomputeOptions();
    },
  );
}

void toggleBranch(String code) {
  final next = List<String>.from(state.selectedBranchCodes);
  next.contains(code) ? next.remove(code) : next.add(code);
  OnboardV2Tracking.track(next.contains(code) ? TrackingKey.onboardV2PathSelect : TrackingKey.onboardV2PathUnselect, parameters: {'branch_code': code});
  emit(state.copyWith(selectedBranchCodes: next));
  _recomputeOptions();
}

void togglePackage(String code) {
  if (!state.problemOptions.any((p) => p.code == code)) return;
  final next = List<String>.from(state.selectedPackageCodes);
  next.contains(code) ? next.remove(code) : next.add(code);
  emit(state.copyWith(selectedPackageCodes: next));
  _recomputeOptions();
}

void selectDesire(String code) {
  if (!state.desireOptions.any((p) => p.code == code)) return;
  emit(state.copyWith(selectedDesireCode: code));
}

/// Gọi sau mọi thay đổi ở câu 1/câu 2: lọc lại đáp án hợp lệ, cắt lựa chọn đã mất.
void _recomputeOptions() {
  final problemOptions = OnboardV2SelectionRules.problemOptions(state.taxonomy, state.selectedBranchCodes);
  final allowed = {for (final p in problemOptions) p.code};
  final packages = state.selectedPackageCodes.where(allowed.contains).toList();
  final desireOptions = OnboardV2SelectionRules.desireOptions(state.taxonomy, packages, seed: OnboardV2SelectionRules.seedFor(packages));
  final desire = desireOptions.any((p) => p.code == state.selectedDesireCode) ? state.selectedDesireCode : null;
  _invalidateRecommendation();
  emit(state.copyWith(
    problemOptions: problemOptions, selectedPackageCodes: packages, desireOptions: desireOptions, selectedDesireCode: desire,
    recommendStatus: OnboardV2RecommendStatus.initial, recommendedCourses: const [], matchReasons: const {}, currentCourseIndex: 0,
  ));
}

Future<void> submitReminder({required bool enabled, required OnboardV2NotificationStatus notificationStatus}) async {
  OnboardV2Tracking.track(enabled ? TrackingKey.onboardV2NotificationNotifyClick : TrackingKey.onboardV2NotificationMaybeLaterClick,
      parameters: {'noti_allow': enabled ? 'yes' : 'no', 'reminder_time': enabled ? state.reminderTime : null});
  emit(state.copyWith(reminderEnabled: enabled, notificationStatus: notificationStatus, currentPage: OnboardV2PageStep.p9Loading, loadingStartedAt: DateTime.now()));
  unawaited(prewarmHomeData());
  await _submitAndRecommend();
}

Future<void> retryRecommendation() => _submitAndRecommend();

Future<void> _submitAndRecommend() async {
  final serial = _requestSerial;
  final recSerial = ++_recommendSerial;
  emit(state.copyWith(recommendStatus: OnboardV2RecommendStatus.loading, recommendErrorMessage: null));
  final hasSession = await _ensureAnonymousSession(source: 'p9_submit');
  if (serial != _requestSerial || recSerial != _recommendSerial) return;
  if (!hasSession) { _emitRecommendFallback('no_session'); return; }

  final request = OnboardingAnswersRequest(
    branchCodes: state.selectedBranchCodes,
    packageCodes: state.selectedPackageCodes,
    desireCode: state.selectedDesireCode,
    reminderEnabled: state.reminderEnabled,
    reminderTime: state.reminderEnabled ? state.reminderTime : null,
    ageKey: state.selectedAge?.trackingLabel,
  );
  final result = await _submitAnswersUseCase(request).run();
  if (serial != _requestSerial || recSerial != _recommendSerial) return;
  result.fold(
    (failure) => _emitRecommendFallback(OnboardV2Tracking.exceptionReason(failure)),
    (rec) {
      if (rec.courses.isEmpty) { _emitRecommendFallback('empty_courses'); return; }
      OnboardV2Tracking.track(TrackingKey.onboardV2CoursesLoaded, parameters: {'course_ids': rec.courses.map((c) => c.id).toList()});
      emit(state.copyWith(recommendStatus: OnboardV2RecommendStatus.loaded, recommendedCourses: rec.courses, matchReasons: rec.matchReasons, currentCourseIndex: 0));
    },
  );
}

void _emitRecommendFallback(String reason) {
  OnboardV2Tracking.track(TrackingKey.onboardV2CoursesFailure, parameters: {'reason': reason});
  emit(state.copyWith(recommendStatus: OnboardV2RecommendStatus.fallback, recommendErrorMessage: reason, recommendedCourses: const [], matchReasons: const {}));
}

/// Loading page gọi khi (đã ≥2,4s) && recommendStatus != loading.
void finishLoading() {
  if (state.currentPage != OnboardV2PageStep.p9Loading) return;
  emit(state.copyWith(currentPage: OnboardV2PageStep.p10Result));
}

void goToThemeWithCourse(CourseEntity course) {
  OnboardV2Tracking.track(TrackingKey.onboardV2CourseSelectClick, parameters: OnboardV2Tracking.courseSelectParams(course: course, currentCourseIndex: state.currentCourseIndex));
  OnboardV2Tracking.setUserProperties({'first_course': course.id});
  unawaited(_submitAnswersUseCase(OnboardingAnswersRequest(chosenCourseId: course.id, completed: true)).run());
  emit(state.copyWith(chosenCourse: course, currentPage: OnboardV2PageStep.p11Theme));
}

void goToThemeWithoutCourse() {
  unawaited(_submitAnswersUseCase(const OnboardingAnswersRequest(completed: true)).run());
  emit(state.copyWith(chosenCourse: null, currentPage: OnboardV2PageStep.p11Theme));
}
```
`goBack()`: `if (currentPage == p9Loading || currentPage == p10Result) return;` back events: p3→AgeBack, p4→PathsBack, p5→SymptomBack, p6→InforBack (tái dùng key), p7/p8 → null. `submitAge()` giờ → `p4Branches`. Xoá `togglePath/continueFromP5Paths/continueFromP6PathMap/toggleSymptom/continueFromP7Symptoms/loadCoursesForP8/retryCoursesForP8/_loadCoursesForP8/goToThemeWithSelectedCourse/goToThemeAsBrowse/resolveCourseForHandoff/_invalidateCourses/_emitCoursesFallback` và `_getCourseUseCase` nếu không còn ai dùng (pick_theme sẽ không resolve course nữa — xem Task 6).

- [ ] **Step 3: Tracking**

```dart
// tracking_key.dart — sau onboardV2P9View
static const String onboardV2P10View = 'obd_result_scr_view';
static const String onboardV2P11View = 'obd_theme_scr_view'; // giữ tên cũ của theme cho sheet
static const String onboardV2ReminderTimeSelect = 'obd_reminder_time_select';
```
`_viewEvent`/`_pageName` trong tracking helper: p4Branches→`onboardV2P5View`/`'p4_branches'`, p5Problems→`onboardV2P7View`/`'p5_problems'`, p6Desire→`onboardV2P6View`/`'p6_desire'`, p7How→`onboardV2P6View`/`'p7_how'`, p8Reminder→`onboardV2P4View`/`'p8_reminder'`, p9Loading→`onboardV2P8View`/`'p9_loading'`, p10Result→`onboardV2P10View`/`'p10_result'`, p11Theme→`onboardV2P9View`/`'p11_theme'`. Xoá mọi hàm nhận `OnboardingPath/OnboardingSymptom` (`selectedPathValue`, `_pathSheetValue`, `_symptomSheetValue`, …); thay bằng
```dart
static Map<String, dynamic> selectionParams(OnboardV2State s) => {
  'branch_codes': s.selectedBranchCodes, 'package_codes': s.selectedPackageCodes, 'desire_code': s.selectedDesireCode,
};
```
User properties: `path_selected` = `selectedBranchCodes.join(',')`, `habit_struggle` = `selectedPackageCodes.join(',')`.

- [ ] **Step 4: Config mapper** — bỏ `paths:` khỏi `toOnboardEntity` (OnboardEntity.paths để rỗng), xoá `_mapPaths/_enumSymptomsFor` và import `OnboardV2PathResolver`. Thêm copy key mới vào `_mapCopy`:
```dart
// S4 (paths section)
OnboardCopyEntity(key: 'onboardingV3P4HeadingHighlight', value: paths.headingHighlight),
OnboardCopyEntity(key: 'onboardingV3P4Helper', value: paths.helper),
// S5 (habit)
OnboardCopyEntity(key: 'onboardingV3P5HeadingPrefix', value: habit.heading),
OnboardCopyEntity(key: 'onboardingV3P5HeadingHighlight', value: habit.headingHighlight),
OnboardCopyEntity(key: 'onboardingV3P5Helper', value: habit.subtitle),
// S6 (desire) / S7 (how) / S8 (reminder) / S9 (loading) / S10 (pick)
OnboardCopyEntity(key: 'onboardingV3P6HeadingPrefix', value: config.desire.heading),
OnboardCopyEntity(key: 'onboardingV3P6HeadingHighlight', value: config.desire.headingHighlight),
OnboardCopyEntity(key: 'onboardingV3P6Helper', value: config.desire.helper),
OnboardCopyEntity(key: 'onboardingV3P7Eyebrow', value: config.how.eyebrow),
OnboardCopyEntity(key: 'onboardingV3P7HeadingPrefix', value: config.how.heading),
OnboardCopyEntity(key: 'onboardingV3P7HeadingHighlight', value: config.how.headingHighlight),
for (var i = 0; i < config.how.steps.length && i < 4; i++) ...[
  OnboardCopyEntity(key: 'onboardingV3P7Step${i + 1}Title', value: config.how.steps[i].title),
  OnboardCopyEntity(key: 'onboardingV3P7Step${i + 1}Body', value: config.how.steps[i].body),
],
OnboardCopyEntity(key: 'onboardingV3P7Footer', value: config.how.footer),
OnboardCopyEntity(key: 'onboardingV3P7Cta', value: config.how.ctaLabel),
OnboardCopyEntity(key: 'onboardingV3P8HeadingPrefix', value: config.reminder.heading),
OnboardCopyEntity(key: 'onboardingV3P8HeadingHighlight', value: config.reminder.headingHighlight),
OnboardCopyEntity(key: 'onboardingV3P8Subtitle', value: config.reminder.subtitle),
OnboardCopyEntity(key: 'onboardingV3P8TimeSectionLabel', value: config.reminder.timeSectionLabel),
for (var i = 0; i < config.reminder.presets.length && i < 3; i++)
  OnboardCopyEntity(key: 'onboardingV3P8Preset${i + 1}', value: config.reminder.presets[i].label),
OnboardCopyEntity(key: 'onboardingV3P9HeadingPrefix', value: config.loading.heading),
OnboardCopyEntity(key: 'onboardingV3P9HeadingHighlight', value: config.loading.headingHighlight),
for (var i = 0; i < config.loading.lines.length && i < 4; i++)
  OnboardCopyEntity(key: 'onboardingV3P9Line${i + 1}', value: config.loading.lines[i]),
OnboardCopyEntity(key: 'onboardingV3P10Cta', value: pick.primaryCta),
```
Preset TIME (không phải nhãn) đọc thẳng từ `config.reminder.presets[i].time` → cubit giữ `state.reminderPresets: List<({String label, String time})>`; rỗng thì dùng mặc định `07:00/12:30/21:00` với nhãn l10n.

- [ ] **Step 5: analyze (sẽ đỏ ở trang cũ — chấp nhận tới Task 4) và commit khi `flutter analyze lib/src/onboard_v2/presentation/cubits lib/src/onboard_v2/presentation/helpers` sạch**

```bash
git add lib/core/constants/manual/tracking_key.dart lib/src/onboard_v2/onboard_v2.dart lib/src/onboard_v2/onboard_v2.freezed.dart lib/src/onboard_v2/presentation/cubits/onboard_v2_state.dart lib/src/onboard_v2/presentation/cubits/onboard_v2_cubit.dart lib/src/onboard_v2/presentation/helpers/onboard_v2_tracking_helper.dart lib/src/onboard_v2/presentation/helpers/onboard_v2_config_mapper.dart
git rm lib/src/onboard_v2/presentation/helpers/onboard_v2_path_resolver.dart lib/src/onboard_v2/presentation/helpers/onboard_v2_symptom_selection_mapper.dart lib/src/onboard_v2/presentation/helpers/onboard_v2_random_course_picker.dart
git commit -m "refactor: onboard_v2 cubit chạy trên taxonomy DB — nhánh/gói/mong muốn, gửi câu trả lời lấy gợi ý" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(Có thể gộp commit này với Task 4 nếu muốn cây luôn analyze sạch giữa hai commit.)

---

### Task 4: Trang mới S4–S10 + widget dùng chung + PageView 11 trang

**Files:**
- Create: `presentation/pages/onboard_v2_branch_page.dart`, `onboard_v2_problem_page.dart`, `onboard_v2_desire_page.dart`, `onboard_v2_how_page.dart`, `onboard_v2_reminder_page.dart`, `onboard_v2_loading_page.dart`, `onboard_v2_result_page.dart`
- Create: `presentation/widgets/p8/onboard_v2_time_wheel.dart`, `presentation/widgets/shared/onboard_v2_chip.dart`
- Modify: `presentation/widgets/shared/onboard_v2_selectable_option_row.dart` (+`subtitle`, `+trailingCheck`)
- Modify: `presentation/pages/onboard_v2_page.dart` (children 11 trang), `onboard_v2_age_page.dart` (GridView 2 cột, ô cuối span 2 khi lẻ)
- Delete: `onboard_v2_path_map_page.dart`, `onboard_v2_path_selection_page.dart`, `onboard_v2_symptom_selection_page.dart`, `onboard_v2_notification_page.dart`, `onboard_v2_course_picker_page.dart`, `widgets/p6/onboard_v2_path_map.dart`, `..._node.dart`, `..._painter.dart`, `..._subtitle.dart`
- Modify: `onboard_v2.dart` (parts)

Chuẩn chung mọi trang: `OnboardV2ScreenShell(header: OnboardV2ProgressHeader(activeSegments: k, totalSegments: 7, pageStep: ..., showBack: true, onBack: cubit.goBack), cta: OnboardV2BottomCta(...), child: Column(...))`. Heading = `AppText(prefix, AppStyle.text28 w800)` + `OnboardV2GradientText(highlight)`. Copy qua `onbCopy(state.onboardData, '<key>', fallback: l10n...)`. k: name=1, age=2, branches=3, problems=4, desire=5, how=6, reminder=7.

- [ ] **Step 1: Widget dùng chung**

```dart
// onboard_v2_selectable_option_row.dart — thêm tham số
final String? subtitle;          // dòng phụ 12px màu textSecondary (S4)
final bool trailingCheck;        // S6: vòng tròn brand có ✓ khi selected (mặc định true, giữ hành vi cũ)
// render subtitle dưới label khi != null && isNotEmpty (AppStyle.text12, height 1.4, color selected ? brandPrimary.op(.8) : textSecondary)
```
```dart
// onboard_v2_chip.dart (part of onboard_v2.dart)
class OnboardV2Chip extends StatelessWidget {
  const OnboardV2Chip({super.key, required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () { AppHaptic.select(); onTap(); },
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: selected ? AppCustomColor.brandPrimary.op(0.08) : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary, width: 1.5.w),
        ),
        child: AppText(label, maxLines: 2, style: AppStyle.text14.copyWith(color: selected ? AppCustomColor.brandPrimary : AppCustomColor.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
      ),
    );
  }
}
```
```dart
// widgets/p8/onboard_v2_time_wheel.dart — hh:mm, phút bước 15 (design: cuộn/kéo, mũi tên trên/dưới)
class OnboardV2TimeWheel extends StatefulWidget {
  const OnboardV2TimeWheel({super.key, required this.value, required this.onChanged});
  final String value;                 // 'HH:mm'
  final ValueChanged<String> onChanged;
  @override State<OnboardV2TimeWheel> createState() => _OnboardV2TimeWheelState();
}
class _OnboardV2TimeWheelState extends State<OnboardV2TimeWheel> {
  static const _minutes = [0, 15, 30, 45];
  late FixedExtentScrollController _hour;
  late FixedExtentScrollController _minute;
  @override void initState() { super.initState(); final p = _parse(widget.value); _hour = FixedExtentScrollController(initialItem: p.$1); _minute = FixedExtentScrollController(initialItem: _minutes.indexOf(p.$2).clamp(0, 3)); }
  @override void didUpdateWidget(covariant OnboardV2TimeWheel old) { super.didUpdateWidget(old); if (old.value != widget.value) { final p = _parse(widget.value); if (_hour.hasClients && _hour.selectedItem != p.$1) _hour.jumpToItem(p.$1); final mi = _minutes.indexOf(p.$2).clamp(0, 3); if (_minute.hasClients && _minute.selectedItem != mi) _minute.jumpToItem(mi); } }
  @override void dispose() { _hour.dispose(); _minute.dispose(); super.dispose(); }
  (int, int) _parse(String v) { final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(v); return (int.tryParse(m?.group(1) ?? '') ?? 21, int.tryParse(m?.group(2) ?? '') ?? 0); }
  void _emit() { final h = _hour.selectedItem % 24; final m = _minutes[_minute.selectedItem % 4]; widget.onChanged('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'); }
  Widget _wheel(FixedExtentScrollController c, int count, String Function(int) label) => SizedBox(
    width: 88.w, height: 156.h,
    child: ListWheelScrollView.useDelegate(
      controller: c, itemExtent: 52.h, perspective: 0.003, diameterRatio: 1.6, physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (_) { AppHaptic.select(); _emit(); },
      childDelegate: ListWheelChildLoopingListDelegate(children: [
        for (var i = 0; i < count; i++) Center(child: AppText(label(i), style: AppStyle.text32.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary))),
      ]),
    ),
  );
  @override Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    decoration: BoxDecoration(color: AppCustomColor.backgroundGray, borderRadius: BorderRadius.circular(20.r)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _wheel(_hour, 24, (i) => i.toString().padLeft(2, '0')),
      AppText(':', style: AppStyle.text32.copyWith(fontWeight: FontWeight.w700)),
      _wheel(_minute, 4, (i) => _minutes[i].toString().padLeft(2, '0')),
    ]),
  );
}
```

- [ ] **Step 2: Trang S4 nhánh** (`onboard_v2_branch_page.dart`)
- Heading: `onbCopy(..., 'onboardingV3P4HeadingPrefix', fallback: l10n.onboardingV3P4HeadingPrefix(name: state.name.trim().isEmpty ? l10n.onboardingV3You : state.name.trim()))` — CHÚ Ý config `paths.heading` không có `{name}`; nếu config có chữ thì dùng nguyên, không thì l10n với tên. Highlight `onboardingV3P4HeadingHighlight`, helper `onboardingV3P4Helper`.
- Body: `taxonomyStatus == loading` → `CircularProgressIndicator`; `failure` → `_InlineError(message: state.taxonomyErrorMessage ?? l10n.onboardingV3TaxonomyLoadError, onRetry: cubit.loadTaxonomy)` (class `_InlineError` đang ở age_page — chuyển sang file shared `onboard_v2_inline_error.dart` để dùng chung); `success` → `for branch in taxonomy.selectableBranches: OnboardV2SelectableOptionRow(label: branch.label.text, subtitle: branch.subtitle.text, iconPath: branch.iconUrl.isNotEmpty ? branch.iconUrl : null, selected: state.selectedBranchCodes.contains(branch.code), onTap: () => cubit.toggleBranch(branch.code))`.
- CTA: `onboardingV2ContinueCta`, enabled `state.canContinueBranches`.

- [ ] **Step 3: Trang S5 vấn đề** (`onboard_v2_problem_page.dart`) — heading `onboardingV3P5HeadingPrefix/Highlight`, helper `onboardingV3P5Helper`; `Wrap(spacing: 9.w, runSpacing: 9.h, children: state.problemOptions.map((p) => OnboardV2Chip(label: p.problemLabel.text, selected: state.selectedPackageCodes.contains(p.code), onTap: () => cubit.togglePackage(p.code))))`; rỗng → `_InlineError(message: l10n.onboardingV3PickBranchFirst, onRetry: cubit.goBack)`. CTA enabled `canContinueProblems`.

- [ ] **Step 4: Trang S6 mong muốn** (`onboard_v2_desire_page.dart`) — heading `onboardingV3P6HeadingPrefix/Highlight` (prefix dài, `maxLines: 3`), helper `onboardingV3P6Helper`; rows `OnboardV2SelectableOptionRow(label: p.desireLabel.text, selected: state.selectedDesireCode == p.code, trailingCheck: true, onTap: () => cubit.selectDesire(p.code))`. CTA enabled `canContinueDesire` (single select).

- [ ] **Step 5: Trang S7 cách HDDhistory dạy** (`onboard_v2_how_page.dart`) — eyebrow `onboardingV3P7Eyebrow` (text12 w700 brand, uppercase), heading `onboardingV3P7HeadingPrefix` + highlight; 4 hàng: vòng số `Container(36.w, shape circle, color brandPrimary.op(.1))` + title (text16 w700) + body (text14 textSecondary, `maxLines: 3`); footer `onboardingV3P7Footer` (text14 textSecondary, `maxLines: 4`); CTA `onboardingV3P7Cta` → `cubit.continueFromP7How()`.

- [ ] **Step 6: Trang S8 nhắc nhở** (`onboard_v2_reminder_page.dart`, StatefulWidget như notification page cũ)
- Giữ toàn bộ logic permission của `onboard_v2_notification_page.dart` cũ (`refreshPermissionState` trong initState, `_handlePrimary` xin quyền qua `enableFromOnboardingGate`, `_handleSecondary` gọi `disableAppPreference`), chỉ đổi `_complete`: `context.read<UserCubit>().completeFirstTimeNotificationGate(); await cubit.submitReminder(enabled: <true|false>, notificationStatus: status);`.
- Body: heading `onboardingV3P8HeadingPrefix/Highlight`, subtitle `onboardingV3P8Subtitle`; `OnboardV2TimeWheel(value: state.reminderTime, onChanged: cubit.setReminderTime)`; `OnboardV2NotificationPreview()` thu nhỏ (`SizedBox(height: 180.h, child: FittedBox(...))`, hoặc chỉ `OnboardV2FloatingNotificationCard` trong Container bo tròn nền xám); label `onboardingV3P8TimeSectionLabel` (text12 w700 textSecondary); `Row` 3 `OnboardV2Chip` preset (label từ `state.reminderPresets[i].label`, selected khi `state.reminderTime == preset.time`, onTap `cubit.setReminderTime(preset.time)`).
- CTA primary `onboardingV2NotifyCta` (loading khi `_isHandling`), secondary `onboardingV2MaybeLaterCta`. `PopScope(canPop: false)`.

- [ ] **Step 7: Trang S9 loading** (`onboard_v2_loading_page.dart`, Stateful)
- Không header/CTA (`OnboardV2ScreenShell(cta: SizedBox.shrink(), child: ...)`). Heading `onboardingV3P9HeadingPrefix/Highlight` căn giữa. 4 dòng `onboardingV3P9Line1..4`: mỗi dòng xuất hiện theo `AnimatedOpacity` với delay 0/500/1000/1500 ms, icon tick tròn brand khi "xong".
- Timer: `initState` → `Future.delayed(2400ms)` rồi `_tryFinish()`; đồng thời `BlocListener<OnboardV2Cubit>` `listenWhen: recommendStatus đổi` → `_tryFinish()`. `_tryFinish`: nếu `elapsed >= 2400ms && cubit.state.recommendStatus != loading` → `cubit.finishLoading()`. Tối đa 12s: nếu vẫn loading → cũng `finishLoading()` (trang kết quả hiện fallback + Thử lại).

- [ ] **Step 8: Trang S10 kết quả** (`onboard_v2_result_page.dart`) — chuyển nội dung `onboard_v2_course_picker_page.dart` sang: giữ `_CourseCarousel/_BestMatchedLabel/_CurrentCourseText/_FallbackContent`, đổi nguồn `state.recommendStatus/recommendedCourses`; eyebrow `onboardingV2P8Eyebrow` (fallback mới "Dựa trên câu trả lời của bạn"), title `onboardingV2P8Title` (fallback "Lựa chọn khoá học đầu tiên"); dưới `_CurrentCourseText` thêm dòng lý do khi `matchReasons[course.id]?.desire == true`: `l10n.onboardingV3ResultReasonDesire` (text12 brand). CTA `onboardingV3P10Cta` → `cubit.goToThemeWithCourse(course)`; fallback: primary `onboardingV2RetryCta` → `cubit.retryRecommendation()`, secondary `onboardingV2P8CatalogCta` → `cubit.goToThemeWithoutCourse()`. `PopScope(canPop: false)`. Vẫn gọi `requestTrackingPermission()` ở `initState` như trang cũ.

- [ ] **Step 9: Age grid 2 cột** — trong `onboard_v2_age_page.dart` thay `...state.onboardData.age.map(...)` bằng `Wrap(spacing: 12.w, runSpacing: 12.h, children: [for (i, age) ...: SizedBox(width: isLastOdd ? full : (full - 12.w) / 2, child: OnboardV2SelectableOptionRow(label: ..., selected: ..., onTap: ..., trailingCheck: false))])` với `full = MediaQuery.sizeOf(context).width - 40.w`; label căn giữa (thêm `centered: true` cho row hoặc dùng widget nhỏ `_AgeTile`).

- [ ] **Step 10: PageView + barrel + xoá file cũ**

```dart
children: const [
  OnboardV2IntroPage(), OnboardV2NamePage(), OnboardV2AgePage(), OnboardV2BranchPage(), OnboardV2ProblemPage(),
  OnboardV2DesirePage(), OnboardV2HowPage(), OnboardV2ReminderPage(), OnboardV2LoadingPage(), OnboardV2ResultPage(), OnboardV2PickThemePage(),
],
```
Barrel: thêm part trang/widget mới, bỏ part file xoá. Chạy `flutter analyze lib/src/onboard_v2` → No issues.

- [ ] **Step 11: Commit**

```bash
git add lib/src/onboard_v2/onboard_v2.dart lib/src/onboard_v2/presentation/pages/onboard_v2_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_age_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_branch_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_problem_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_desire_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_how_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_reminder_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_loading_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_result_page.dart lib/src/onboard_v2/presentation/widgets/p8/onboard_v2_time_wheel.dart lib/src/onboard_v2/presentation/widgets/shared/onboard_v2_chip.dart lib/src/onboard_v2/presentation/widgets/shared/onboard_v2_selectable_option_row.dart lib/src/onboard_v2/presentation/widgets/shared/onboard_v2_inline_error.dart
git rm lib/src/onboard_v2/presentation/pages/onboard_v2_path_map_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_path_selection_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_symptom_selection_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_notification_page.dart lib/src/onboard_v2/presentation/pages/onboard_v2_course_picker_page.dart lib/src/onboard_v2/presentation/widgets/p6/onboard_v2_path_map.dart lib/src/onboard_v2/presentation/widgets/p6/onboard_v2_path_map_node.dart lib/src/onboard_v2/presentation/widgets/p6/onboard_v2_path_map_painter.dart lib/src/onboard_v2/presentation/widgets/p6/onboard_v2_path_map_subtitle.dart
git commit -m "feat: onboarding 12 màn theo design — lĩnh vực/vấn đề/mong muốn, cách dạy, nhắc học có giờ, loading, 3 card kết quả" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: l10n — key mới cho 5 locale

**Files:** `assets/i18n/{en,vi,zh,ja,ko}/onboarding.yaml`, rồi `dart run slang` (sinh `lib/config/l10n/*`).

- [ ] **Step 1: Thêm khối sau các key `onboardingV2*`** (vi/en đầy đủ dưới đây; zh/ja/ko điền cùng key với bản dịch tương ứng — dùng bản dưới):

```yaml
# vi
onboardingV3You: bạn
onboardingV3P4HeadingPrefix: ${name} muốn
onboardingV3P4HeadingHighlight: cải thiện điều gì?
onboardingV3P4Helper: Chọn tất cả những điều đúng với bạn.
onboardingV3P5HeadingPrefix: Bạn thấy mình
onboardingV3P5HeadingHighlight: ở đâu trong đây?
onboardingV3P5Helper: Chọn tất cả những điều đúng với bạn.
onboardingV3P6HeadingPrefix: Nếu chỉ được thay đổi một thứ trong 10 ngày tới,
onboardingV3P6HeadingHighlight: bạn chọn gì?
onboardingV3P6Helper: Chọn một điều quan trọng nhất với bạn.
onboardingV3P7Eyebrow: HDDhistory giúp bạn thế nào
onboardingV3P7HeadingPrefix: Không dừng ở biết
onboardingV3P7HeadingHighlight: Mà phải ứng dụng được
onboardingV3P7Step1Title: Hiểu
onboardingV3P7Step1Body: Bài học siêu ngắn, vừa với lịch của bạn
onboardingV3P7Step2Title: Thử
onboardingV3P7Step2Body: Luyện tập cùng AI ngay sau khi học
onboardingV3P7Step3Title: Ôn
onboardingV3P7Step3Body: HDDhistory nhắc lại trước khi bạn kịp quên
onboardingV3P7Step4Title: Dùng
onboardingV3P7Step4Body: Hướng dẫn mang bài học vào việc thật mỗi ngày
onboardingV3P7Footer: HDDhistory đi cùng bạn ở từng bước, từ bài học đầu tiên đến thói quen bạn giữ được mỗi ngày.
onboardingV3P7Cta: Bắt đầu thôi
onboardingV3P8HeadingPrefix: Khó nhất không phải bắt đầu,
onboardingV3P8HeadingHighlight: mà là duy trì
onboardingV3P8Subtitle: Lời nhắc đúng giờ giúp bạn không bỏ lỡ ngày nào
onboardingV3P8TimeSectionLabel: CHỌN KHUNG GIỜ HỌC ƯA THÍCH
onboardingV3P8Preset1: Sáng · 7:00
onboardingV3P8Preset2: Trưa · 12:30
onboardingV3P8Preset3: Tối · 21:00
onboardingV3P9HeadingPrefix: Đề xuất khoá học
onboardingV3P9HeadingHighlight: dành cho bạn
onboardingV3P9Line1: Lĩnh vực bạn quan tâm
onboardingV3P9Line2: Điều bạn đang vướng
onboardingV3P9Line3: Điều bạn muốn thay đổi
onboardingV3P9Line4: Khung giờ học ưa thích
onboardingV3P10Cta: Học bài đầu tiên
onboardingV3ResultReasonDesire: Khớp đúng điều bạn muốn thay đổi
onboardingV3TaxonomyLoadError: Không tải được danh sách lĩnh vực
onboardingV3PickBranchFirst: Chọn lĩnh vực ở bước trước đã
```
Đổi fallback cũ: `onboardingV2P8Eyebrow: Dựa trên câu trả lời của bạn`, `onboardingV2P8Title: Lựa chọn khoá học đầu tiên`, `onboardingV2P8Label: Phù hợp nhất` (giữ).

```yaml
# en
onboardingV3You: you
onboardingV3P4HeadingPrefix: ${name}, what do you want
onboardingV3P4HeadingHighlight: to improve?
onboardingV3P4Helper: Pick everything that sounds like you.
onboardingV3P5HeadingPrefix: Where do you
onboardingV3P5HeadingHighlight: see yourself here?
onboardingV3P5Helper: Pick everything that sounds like you.
onboardingV3P6HeadingPrefix: If you could change one thing in the next 10 days,
onboardingV3P6HeadingHighlight: what would it be?
onboardingV3P6Helper: Pick the one that matters most.
onboardingV3P7Eyebrow: How HDDhistory helps
onboardingV3P7HeadingPrefix: Not just knowing
onboardingV3P7HeadingHighlight: but putting it to use
onboardingV3P7Step1Title: Learn
onboardingV3P7Step1Body: Bite-size lessons that fit your day
onboardingV3P7Step2Title: Try
onboardingV3P7Step2Body: Practice with AI right after each lesson
onboardingV3P7Step3Title: Review
onboardingV3P7Step3Body: HDDhistory reminds you before you forget
onboardingV3P7Step4Title: Apply
onboardingV3P7Step4Body: Guidance to use it in real life, every day
onboardingV3P7Footer: HDDhistory walks with you every step, from the first lesson to the habit you keep.
onboardingV3P7Cta: Let's go
onboardingV3P8HeadingPrefix: The hard part isn't starting,
onboardingV3P8HeadingHighlight: it's keeping going
onboardingV3P8Subtitle: A well-timed reminder keeps every day on track
onboardingV3P8TimeSectionLabel: PICK YOUR STUDY TIME
onboardingV3P8Preset1: Morning · 7:00
onboardingV3P8Preset2: Noon · 12:30
onboardingV3P8Preset3: Evening · 21:00
onboardingV3P9HeadingPrefix: Picking a course
onboardingV3P9HeadingHighlight: for you
onboardingV3P9Line1: What you care about
onboardingV3P9Line2: What's in your way
onboardingV3P9Line3: What you want to change
onboardingV3P9Line4: Your study time
onboardingV3P10Cta: Start the first lesson
onboardingV3ResultReasonDesire: Matches what you want to change
onboardingV3TaxonomyLoadError: Couldn't load the topics
onboardingV3PickBranchFirst: Pick a topic in the previous step first
```
```yaml
# zh
onboardingV3You: 你
onboardingV3P4HeadingPrefix: ${name}，你想
onboardingV3P4HeadingHighlight: 改善什么？
onboardingV3P4Helper: 选出所有符合你的选项。
onboardingV3P5HeadingPrefix: 你觉得自己
onboardingV3P5HeadingHighlight: 在这里的哪一项？
onboardingV3P5Helper: 选出所有符合你的选项。
onboardingV3P6HeadingPrefix: 如果接下来10天只能改变一件事，
onboardingV3P6HeadingHighlight: 你会选什么？
onboardingV3P6Helper: 选一个对你最重要的。
onboardingV3P7Eyebrow: HDDhistory 如何帮你
onboardingV3P7HeadingPrefix: 不止于知道
onboardingV3P7HeadingHighlight: 更要用得上
onboardingV3P7Step1Title: 学
onboardingV3P7Step1Body: 超短课程，贴合你的日程
onboardingV3P7Step2Title: 练
onboardingV3P7Step2Body: 学完立刻和 AI 一起练习
onboardingV3P7Step3Title: 复习
onboardingV3P7Step3Body: 在你忘记之前 HDDhistory 会提醒你
onboardingV3P7Step4Title: 用
onboardingV3P7Step4Body: 引导你每天把所学用到真实生活
onboardingV3P7Footer: 从第一课到每天坚持的习惯，HDDhistory 陪你走每一步。
onboardingV3P7Cta: 开始吧
onboardingV3P8HeadingPrefix: 最难的不是开始，
onboardingV3P8HeadingHighlight: 而是坚持
onboardingV3P8Subtitle: 准时的提醒让你一天都不落下
onboardingV3P8TimeSectionLabel: 选择你的学习时段
onboardingV3P8Preset1: 早上 · 7:00
onboardingV3P8Preset2: 中午 · 12:30
onboardingV3P8Preset3: 晚上 · 21:00
onboardingV3P9HeadingPrefix: 正在为你
onboardingV3P9HeadingHighlight: 推荐课程
onboardingV3P9Line1: 你关注的领域
onboardingV3P9Line2: 你正卡住的地方
onboardingV3P9Line3: 你想改变的事
onboardingV3P9Line4: 你的学习时段
onboardingV3P10Cta: 开始第一课
onboardingV3ResultReasonDesire: 正好对应你想改变的事
onboardingV3TaxonomyLoadError: 无法加载领域列表
onboardingV3PickBranchFirst: 请先在上一步选择领域
```
```yaml
# ja
onboardingV3You: あなた
onboardingV3P4HeadingPrefix: ${name}さんが
onboardingV3P4HeadingHighlight: 良くしたいことは？
onboardingV3P4Helper: 当てはまるものをすべて選んでください。
onboardingV3P5HeadingPrefix: この中で自分に
onboardingV3P5HeadingHighlight: 近いのはどれ？
onboardingV3P5Helper: 当てはまるものをすべて選んでください。
onboardingV3P6HeadingPrefix: これから10日で1つだけ変えられるなら、
onboardingV3P6HeadingHighlight: 何を選びますか？
onboardingV3P6Helper: いちばん大切なものを1つ選んでください。
onboardingV3P7Eyebrow: HDDhistory があなたを支える方法
onboardingV3P7HeadingPrefix: 知るだけで終わらせない
onboardingV3P7HeadingHighlight: 使えるようになる
onboardingV3P7Step1Title: 学ぶ
onboardingV3P7Step1Body: 予定に収まる超短時間レッスン
onboardingV3P7Step2Title: 試す
onboardingV3P7Step2Body: 学んだ直後に AI と練習
onboardingV3P7Step3Title: 復習
onboardingV3P7Step3Body: 忘れる前に HDDhistory がリマインド
onboardingV3P7Step4Title: 使う
onboardingV3P7Step4Body: 学びを毎日の実生活に活かすガイド
onboardingV3P7Footer: 最初のレッスンから続けられる習慣まで、HDDhistory が一歩ずつ伴走します。
onboardingV3P7Cta: はじめよう
onboardingV3P8HeadingPrefix: いちばん難しいのは始めることではなく、
onboardingV3P8HeadingHighlight: 続けること
onboardingV3P8Subtitle: ちょうどいい時間のリマインドで一日も逃さない
onboardingV3P8TimeSectionLabel: 学習する時間帯を選ぶ
onboardingV3P8Preset1: 朝 · 7:00
onboardingV3P8Preset2: 昼 · 12:30
onboardingV3P8Preset3: 夜 · 21:00
onboardingV3P9HeadingPrefix: あなたに合う
onboardingV3P9HeadingHighlight: コースを選んでいます
onboardingV3P9Line1: 関心のある分野
onboardingV3P9Line2: 今つまずいていること
onboardingV3P9Line3: 変えたいこと
onboardingV3P9Line4: 学習の時間帯
onboardingV3P10Cta: 最初のレッスンへ
onboardingV3ResultReasonDesire: 変えたいことにぴったり
onboardingV3TaxonomyLoadError: 分野の一覧を読み込めませんでした
onboardingV3PickBranchFirst: 前のステップで分野を選んでください
```
```yaml
# ko
onboardingV3You: 당신
onboardingV3P4HeadingPrefix: ${name}님이
onboardingV3P4HeadingHighlight: 개선하고 싶은 건?
onboardingV3P4Helper: 해당하는 것을 모두 선택하세요.
onboardingV3P5HeadingPrefix: 이 중에서 나와
onboardingV3P5HeadingHighlight: 가장 가까운 건?
onboardingV3P5Helper: 해당하는 것을 모두 선택하세요.
onboardingV3P6HeadingPrefix: 앞으로 10일 동안 하나만 바꿀 수 있다면,
onboardingV3P6HeadingHighlight: 무엇을 고르시겠어요?
onboardingV3P6Helper: 가장 중요한 하나만 선택하세요.
onboardingV3P7Eyebrow: HDDhistory이 돕는 방법
onboardingV3P7HeadingPrefix: 아는 데서 멈추지 않고
onboardingV3P7HeadingHighlight: 실제로 쓸 수 있게
onboardingV3P7Step1Title: 배우기
onboardingV3P7Step1Body: 일정에 딱 맞는 초단기 레슨
onboardingV3P7Step2Title: 해보기
onboardingV3P7Step2Body: 배운 직후 AI와 바로 연습
onboardingV3P7Step3Title: 복습
onboardingV3P7Step3Body: 잊기 전에 HDDhistory이 다시 알려줘요
onboardingV3P7Step4Title: 적용
onboardingV3P7Step4Body: 배운 것을 매일 실제 상황에 쓰도록 안내
onboardingV3P7Footer: 첫 레슨부터 매일 지키는 습관까지, HDDhistory이 한 걸음씩 함께합니다.
onboardingV3P7Cta: 시작하기
onboardingV3P8HeadingPrefix: 가장 어려운 건 시작이 아니라
onboardingV3P8HeadingHighlight: 꾸준히 하는 것
onboardingV3P8Subtitle: 딱 맞는 시간의 알림으로 하루도 놓치지 않아요
onboardingV3P8TimeSectionLabel: 선호하는 학습 시간 선택
onboardingV3P8Preset1: 아침 · 7:00
onboardingV3P8Preset2: 점심 · 12:30
onboardingV3P8Preset3: 저녁 · 21:00
onboardingV3P9HeadingPrefix: 당신을 위한
onboardingV3P9HeadingHighlight: 코스를 고르고 있어요
onboardingV3P9Line1: 관심 있는 분야
onboardingV3P9Line2: 지금 막히는 것
onboardingV3P9Line3: 바꾸고 싶은 것
onboardingV3P9Line4: 선호하는 학습 시간
onboardingV3P10Cta: 첫 레슨 시작하기
onboardingV3ResultReasonDesire: 바꾸고 싶은 것과 정확히 맞아요
onboardingV3TaxonomyLoadError: 분야 목록을 불러오지 못했어요
onboardingV3PickBranchFirst: 이전 단계에서 분야를 먼저 선택하세요
```

- [ ] **Step 2: Sinh + analyze + commit**

Run: `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/dart run slang` → không lỗi key thiếu; `flutter analyze lib/src/onboard_v2` → No issues.
```bash
git add assets/i18n/en/onboarding.yaml assets/i18n/vi/onboarding.yaml assets/i18n/zh/onboarding.yaml assets/i18n/ja/onboarding.yaml assets/i18n/ko/onboarding.yaml lib/config/l10n/l10n.g.dart lib/config/l10n/l10n_vi.g.dart lib/config/l10n/l10n_zh.g.dart lib/config/l10n/l10n_ja.g.dart lib/config/l10n/l10n_ko.g.dart
git commit -m "feat: copy 5 ngôn ngữ cho các màn onboarding mới" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(Đọc `git status --short lib/config/l10n` để add đúng các file slang thật sự đổi.)

---

### Task 6: Theme → Home; Home xếp skillset theo nhánh đã chọn

**Files:**
- Modify: `lib/src/onboard_v2/presentation/pages/onboard_v2_pick_theme_page.dart:130-206`
- Modify: `lib/src/auth/presentation/cubits/user_state.dart:18`, `user_cubit.dart:90, 243-251`
- Modify: `lib/src/home/presentation/cubits/home_state.dart:45-92`

- [ ] **Step 1: UserCubit** — `onboardingPathOrder: List<OnboardingPath>` → `@Default([]) List<String> onboardingSkillsetOrder`; setter `void setOnboardingSkillsetOrder(List<String> skillsetIds)`; `clearData()` giữ field mới thay field cũ. Chạy build_runner (auth.freezed/g).

- [ ] **Step 2: home_state** — thay hai hàm cuối:
```dart
/// Thứ tự skillset theo nhánh user chọn ở onboarding (branch.skillsetId, theo
/// thứ tự chọn) — xem [UserCubit.setOnboardingSkillsetOrder]. Skillset ngoài
/// danh sách (hoặc chưa set) giữ thứ tự backend, xếp sau.
List<SkillsetEntity> get skillsets => _orderSkillsetsByIds(pageData.items, AppDI.injector.get<UserCubit>().state.onboardingSkillsetOrder);

List<SkillsetEntity> _orderSkillsetsByIds(List<SkillsetEntity> skillsets, List<String> idOrder) {
  if (idOrder.isEmpty || skillsets.isEmpty) return skillsets;
  final buckets = List<List<SkillsetEntity>>.generate(idOrder.length, (_) => []);
  final unranked = <SkillsetEntity>[];
  for (final skillset in skillsets) {
    final rank = idOrder.indexOf(skillset.id);
    if (rank >= 0) buckets[rank].add(skillset); else unranked.add(skillset);
  }
  return [...buckets.expand((b) => b), ...unranked];
}
```
Xoá `_skillsetIntroduceForPath` và import `OnboardingPath` nếu không còn dùng trong file.

- [ ] **Step 3: pick_theme `_startExplore` + `_dispatchRoute`**

```dart
Future<void> _startExplore() async {
  ... (tracking giữ) ...
  final cubit = context.read<OnboardV2Cubit>();
  final onboardedSave = cubit.markUserOnboarded();
  // Home đã prewarm từ S9; chờ cho xong (hoặc timeout) để Home không lạnh.
  await cubit.prewarmHomeData().timeout(const Duration(seconds: 6), onTimeout: () {});
  if (!mounted) return;
  await onboardedSave.timeout(const Duration(seconds: 6), onTimeout: () {});
  if (!mounted) return;
  _dispatchHome();
}

void _dispatchHome() {
  try {
    final onboardCubit = context.read<OnboardV2Cubit>();
    final userCubit = context.read<UserCubit>();
    userCubit.setOnboardingSkillsetOrder(onboardCubit.state.selectedSkillsetIds);
    OnboardV2Tracking.track(TrackingKey.onboardV2Complete, parameters: {'chosen_course_id': onboardCubit.state.chosenCourse?.id});
    HomeRoute().go(context);
    context.read<PageCubit>().setCurrentRouteName(RouteNamed.home);
    userCubit.setIsUserPassOnboarding(false);
    _maybeShowPostOnboardingPaywall(onboardCubit.state.showPaywallAfterOnboarding);
  } catch (error) {
    LogDev.warning('[OnboardV2PickThemePage] route dispatch failed: $error');
    if (mounted) setState(() => _isNavigating = false);
  }
}
```
Kiểm `RouteNamed.home` tồn tại (grep `RouteNamed` trong lib/config/routes); nếu tên khác dùng đúng tên. Bỏ import `CourseHandoffHelper`/`CourseRoadmapCubit` nếu không còn dùng ở file này.

- [ ] **Step 4: analyze toàn bộ + commit**

Run: `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && /Users/nguyenvietha/development/flutter/bin/dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3 && /Users/nguyenvietha/development/flutter/bin/flutter analyze` → No issues (toàn repo — vì có thể còn chỗ khác tham chiếu `onboardingPathOrder`; grep `onboardingPathOrder` phải = 0 ngoài generated).
```bash
git add lib/src/onboard_v2/presentation/pages/onboard_v2_pick_theme_page.dart lib/src/auth/presentation/cubits/user_state.dart lib/src/auth/presentation/cubits/user_cubit.dart lib/src/auth/auth.freezed.dart lib/src/auth/auth.g.dart lib/src/home/presentation/cubits/home_state.dart
git commit -m "feat: sau chọn theme về Home; Home xếp skillset theo nhánh đã chọn ở onboarding" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
(Đường dẫn file freezed/g của auth: kiểm bằng `git status --short lib/src/auth`.)

---

### Task 7: Dọn scaffold chết + chạy simulator

**Files:**
- Delete: `lib/src/onboard_v2/data/**`, `lib/src/onboard_v2/domain/**` (onboard_v2_api/model/entity/repository/i_repository/2 usecase), bỏ part trong barrel; `onboard_v2.g.dart` xoá nếu build_runner không sinh nữa.
- Test cũ: `test/unit/onboard_v2/**` tham chiếu `selectedPaths`/`OnboardingSymptom` → sửa hoặc xoá các test không còn đúng (liệt kê file bị hỏng bằng `flutter analyze test/unit/onboard_v2`).

- [ ] **Step 1:** Xoá + build_runner + `flutter analyze` (toàn repo) sạch; `flutter test test/unit/onboard_v2/presentation/helpers/onboard_v2_selection_rules_test.dart` PASS.
- [ ] **Step 2:** Chạy simulator theo skill `build-simulator`/`sim-test` với api-dev đã có taxonomy: đi hết 12 màn, kiểm: S4 hiện 5 nhánh; chọn LV+CX → S5 hiện 10 chip 5/5 xen kẽ; chọn 2 chip → S6 hiện 4 dòng; S8 đổi giờ bằng bánh xe + chip; S9 ≥2,4s; S10 3 card, card 1 badge; theme → Home; Home xếp skillset LV, CX trước.
- [ ] **Step 3:** Commit
```bash
git rm -r lib/src/onboard_v2/data lib/src/onboard_v2/domain
git add lib/src/onboard_v2/onboard_v2.dart   # + test files sửa/xoá, + onboard_v2.g.dart nếu xoá
git commit -m "chore: bỏ scaffold onboard_v2 không dùng, sửa test theo luồng mới" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
