part of '../../../course.dart';

class CourseFilterRequest implements JsonRequestConvertible {
  const CourseFilterRequest({
    this.categoryIds = const [],
    this.onboardingSymptoms = const [],
    this.isAll,
  });

  factory CourseFilterRequest.byCategories(
    Iterable<String> categoryIds, {
    bool isAll = true,
  }) {
    final dedupedIds = <String>[];
    final seenIds = <String>{};

    for (final rawId in categoryIds) {
      final id = rawId.trim();
      if (id.isEmpty || !seenIds.add(id)) continue;
      dedupedIds.add(id);
    }

    return CourseFilterRequest(
      categoryIds: dedupedIds,
      isAll: isAll,
    );
  }

  factory CourseFilterRequest.byOnboardingSymptoms(
    Iterable<OnboardingSymptom> symptoms, {
    bool isAll = true,
  }) {
    final dedupedSymptoms = <OnboardingSymptom>[];
    final seenSymptoms = <OnboardingSymptom>{};

    for (final symptom in symptoms) {
      if (symptom == OnboardingSymptom.unknown || !seenSymptoms.add(symptom)) continue;
      dedupedSymptoms.add(symptom);
    }

    return CourseFilterRequest(
      onboardingSymptoms: dedupedSymptoms,
      isAll: isAll,
    );
  }

  final List<String> categoryIds;
  final List<OnboardingSymptom> onboardingSymptoms;
  final bool? isAll;

  bool get hasFilters => categoryIds.isNotEmpty || onboardingSymptoms.isNotEmpty || isAll != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      if (categoryIds.isNotEmpty) 'categoryIds': ListParam<String>(categoryIds, ListFormat.multi),
      if (onboardingSymptoms.isNotEmpty)
        'onboardingSymptoms': ListParam<String>(
          onboardingSymptoms.map(_onboardingSymptomRequestValue).toList(),
          ListFormat.multi,
        ),
      if (isAll != null) 'isAll': isAll,
    };
  }

  static String _onboardingSymptomRequestValue(OnboardingSymptom symptom) {
    return _$OnboardingSymptomEnumMap[symptom] ?? 'UNKNOWN';
  }
}

@lazySingleton
class GetAllCoursesUseCase implements BaseUseCase<PageBreakRequest<CourseFilterRequest>, BasePageBreak<CourseEntity>> {
  final ICourseRepository _repository;

  GetAllCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> call(PageBreakRequest<CourseFilterRequest> params) {
    return _repository.getAllCourses(params);
  }
}
