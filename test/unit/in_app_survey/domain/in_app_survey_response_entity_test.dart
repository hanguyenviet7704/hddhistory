import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('InAppSurveyResponseEntity', () {
    test('serializes only the backend response contract fields', () {
      const entity = InAppSurveyResponseEntity(
        branchId: 'branch-1',
        selectedOptionIds: ['option-1', 'option-2'],
        feedback: 'Useful, but slow',
      );

      expect(entity.toJson(), {
        'branchId': 'branch-1',
        'selectedOptionIds': ['option-1', 'option-2'],
        'feedback': 'Useful, but slow',
      });
      expect(entity.toJson(), isNot(contains('configKey')));
      expect(entity.toJson(), isNot(contains('closedAnswerIds')));
      expect(entity.toJson(), isNot(contains('openAnswer')));
    });
  });
}
