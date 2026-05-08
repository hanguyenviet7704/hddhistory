part of '../../../course.dart';

class CourseFilterRequest implements JsonRequestConvertible {
  const CourseFilterRequest({
    this.skillsetIds = const [],
    this.onboardingSymptoms = const [],
    this.isAll,
  });

  factory CourseFilterRequest.bySkillsets(
    Iterable<String> skillsetIds, {
    bool isAll = true,
  }) {
    final dedupedIds = <String>[];
    final seenIds = <String>{};

    for (final rawId in skillsetIds) {
      final id = rawId.trim();
      if (id.isEmpty || !seenIds.add(id)) continue;
      dedupedIds.add(id);
    }

    return CourseFilterRequest(
      skillsetIds: dedupedIds,
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

  final List<String> skillsetIds;
  final List<OnboardingSymptom> onboardingSymptoms;
  final bool? isAll;

  bool get hasFilters => skillsetIds.isNotEmpty || onboardingSymptoms.isNotEmpty || isAll != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      if (skillsetIds.isNotEmpty) 'skillsetIds': ListParam<String>(skillsetIds, ListFormat.multi),
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
