import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('NoCorrectAnswerDocument route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.noCorrectAnswerDocument, 'no-correct-answer-document/:groupId');
      expect(RouteNamed.noCorrectAnswerDocument, 'No Correct Answer Document');
    });

    test('builds typed location with group id segment', () {
      const route = NoCorrectAnswerDocumentRoute(groupId: 'group-1');

      expect(route.location, contains('no-correct-answer-document/group-1'));
      expect(route.location, contains('/course-roadmap/'));
    });
  });
}
