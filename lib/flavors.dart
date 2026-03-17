import 'package:firebase_core/firebase_core.dart';

import 'config/services/firebase/firebase_options_dev.dart' as dev;
import 'config/services/firebase/firebase_options_prod.dart' as prod;
import 'config/services/firebase/firebase_options_stg.dart' as stg;

enum Flavor {
  dev,
  stg,
  prod,
}

class F {
  static const String _appEnvironmentKey = 'APP_ENVIRONMENT';
  static Flavor? _appFlavor;

  static Flavor? get appFlavor => _appFlavor ??= _resolveFlavorFromEnvironment();
  static set appFlavor(Flavor? flavor) => _appFlavor = flavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    return switch (appFlavor) {
      Flavor.dev => 'Meup Dev',
      Flavor.stg => 'Meup Staging',
      Flavor.prod => 'Meup',
      _ => 'Meup',
    };
  }

  static FirebaseOptions get firebaseOptions {
    return switch (appFlavor) {
      Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
      Flavor.stg => stg.DefaultFirebaseOptions.currentPlatform,
      Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
      _ => throw UnsupportedError('No Firebase options set for this flavor'),
    };
  }

  static Flavor? _resolveFlavorFromEnvironment() {
    return switch (const String.fromEnvironment(_appEnvironmentKey)) {
      'dev' => Flavor.dev,
      'stg' => Flavor.stg,
      'prod' => Flavor.prod,
      _ => null,
    };
  }
}
