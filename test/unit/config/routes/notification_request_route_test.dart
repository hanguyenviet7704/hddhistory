import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('NotificationRequestRoute', () {
    test('Given default route, When location is built, Then it keeps the base notification gate path', () {
      const route = NotificationRequestRoute();

      expect(route.location, contains(RoutePath.notificationRequest));
      expect(route.location, isNot(contains('show-paywall-after-auth=')));
      expect(route.location, isNot(contains('course-entry-mode=')));
    });

    test('Given course-entry handoff, When location is built, Then it carries the course-entry query flag only', () {
      const route = NotificationRequestRoute(courseEntryMode: true);

      expect(route.location, contains(RoutePath.notificationRequest));
      expect(route.location, contains('course-entry-mode=true'));
      expect(route.location, isNot(contains('show-paywall-after-auth=true')));
    });

    test('Given first-time paywall handoff, When location is built, Then it carries the paywall query flag', () {
      const route = NotificationRequestRoute(showPaywallAfterAuth: true);

      expect(route.location, contains(RoutePath.notificationRequest));
      expect(route.location, contains('show-paywall-after-auth=true'));
    });

    test('Given conflicting handoff flags, When route is created, Then the constructor assert rejects it', () {
      expect(
        () => NotificationRequestRoute(
          courseEntryMode: true,
          showPaywallAfterAuth: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
