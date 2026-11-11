import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('Register route config', () {
    test('Given default route, When location is built, Then it keeps the base register path', () {
      const route = RegisterRoute();

      expect(route.location, contains(RoutePath.register));
      expect(route.location, isNot(contains('force-choose-course-after-login=')));
      expect(route.location, isNot(contains('show-paywall-after-auth=')));
    });

    test('Given forced course chooser handoff, When location is built, Then it carries the scoped query flag', () {
      const route = RegisterRoute(forceChooseCourseAfterLogin: true);

      expect(route.location, contains(RoutePath.register));
      expect(route.location, contains('force-choose-course-after-login=true'));
    });

    test('Given first-time paywall handoff, When location is built, Then it carries the paywall query flag', () {
      const route = RegisterRoute(showPaywallAfterAuth: true);

      expect(route.location, contains(RoutePath.register));
      expect(route.location, contains('show-paywall-after-auth=true'));
    });
  });
}
