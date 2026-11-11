import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('OnboardBranching route config', () {
    test('exposes branching route path and route name constants', () {
      expect(RoutePath.onboardBranching, '/onboard-branching');
      expect(RouteNamed.onboardBranching, 'Onboard Branching Page');
    });

    test('builds typed location with userName query parameter', () {
      const route = OnboardBranchingRoute(userName: 'alex');

      expect(route.location, contains('/onboard-branching'));
      expect(route.location, contains('user-name=alex'));
    });
  });
}
