import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('OnboardV2Route', () {
    test('exposes onboard v2 route path and route name constants', () {
      expect(RoutePath.onboardV2, '/onboard-v2');
      expect(RouteNamed.onboardV2, 'Onboard V2 Page');
    });

    test('builds typed location from the base path', () {
      const route = OnboardV2Route();

      expect(route.location, RoutePath.onboardV2);
    });
  });
}
