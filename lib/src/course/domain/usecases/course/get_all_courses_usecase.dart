part of '../../../course.dart';

class CourseFilterRequest implements JsonRequestConvertible {
  const CourseFilterRequest({
    this.skillsetIds = const [],
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

  final List<String> skillsetIds;
  final bool? isAll;

  bool get hasFilters => skillsetIds.isNotEmpty || isAll != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      if (skillsetIds.isNotEmpty) 'skillsetIds': skillsetIds.join(','),
      if (isAll != null) 'isAll': isAll,
    };
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
