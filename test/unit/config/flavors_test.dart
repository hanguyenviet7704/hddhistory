import 'package:flutter_test/flutter_test.dart';
import 'package:meup/flavors.dart';

void main() {
  group('F', () {
    tearDown(() {
      F.appFlavor = null;
    });

    test('resolves the explicit flavor assignment first', () {
      F.appFlavor = Flavor.stg;

      expect(F.appFlavor, Flavor.stg);
      expect(F.name, 'stg');
      expect(F.title, 'Meup Staging');
    });

    test('falls back to APP_ENVIRONMENT when no flavor was explicitly assigned', () {
      const appEnvironment = String.fromEnvironment('APP_ENVIRONMENT');
      final expectedFlavor = switch (appEnvironment) {
        'dev' => Flavor.dev,
        'stg' => Flavor.stg,
        'prod' => Flavor.prod,
        _ => null,
      };

      F.appFlavor = null;

      expect(F.appFlavor, expectedFlavor);
    });
  });
}
