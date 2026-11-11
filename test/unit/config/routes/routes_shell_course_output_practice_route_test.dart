import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('OutputPractice route config', () {
    test('exposes route path and route name constants', () {
      expect(RoutePath.outputPractice, 'output-practice/:sectionId');
      expect(RouteNamed.outputPractice, 'Output Practice');
    });

    test('builds typed location with section id segment', () {
      const route = OutputPracticeRoute(sectionId: 'section-1');

      expect(route.location, contains('output-practice/section-1'));
      expect(route.location, contains('/course-roadmap/'));
    });
  });
}
