import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('CourseFilterRequest', () {
    test('removes empty ids and dedupes skillset ids while preserving order', () {
      final request = CourseFilterRequest.bySkillsets(['', 'a', 'b', 'a', ' ', 'c']);

      expect(request.skillsetIds, ['a', 'b', 'c']);
    });

    test('serializes skillset ids and isAll for the courses API', () {
      final request = PageBreakRequest<CourseFilterRequest>(
        filter: CourseFilterRequest.bySkillsets(['skillset_1', 'skillset_2']),
      );

      expect(request.toJson(), containsPair('skillsetIds', 'skillset_1, skillset_2'));
      expect(request.toJson(), containsPair('isAll', true));
      expect(request.toJson(), containsPair('page', 1));
      expect(request.toJson(), containsPair('take', 10));
    });
  });
}
