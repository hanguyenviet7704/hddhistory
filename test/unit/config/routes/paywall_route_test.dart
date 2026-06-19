import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('Paywall route config', () {
    test('Given default route, When location is built, Then it keeps the base paywall path', () {
      const route = PaywallRoute();

      expect(route.location, contains(RoutePath.paywall));
      expect(route.location, isNot(contains('first-time-user-flow=')));
    });
  });
}
