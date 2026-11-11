import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('HydrateBlocService storage migration', () {
    late Directory rootDirectory;
    late Directory legacyDirectory;
    late Directory targetDirectory;

    setUp(() async {
      rootDirectory = await Directory.systemTemp.createTemp('hydrated_service_test_');
      legacyDirectory = Directory('${rootDirectory.path}${Platform.pathSeparator}legacy');
      targetDirectory = Directory('${rootDirectory.path}${Platform.pathSeparator}support');
      await legacyDirectory.create(recursive: true);
    });

    tearDown(() async {
      if (rootDirectory.existsSync()) {
        await rootDirectory.delete(recursive: true);
      }
    });

    test('copies legacy hydrated state into durable storage directory', () async {
      await File('${legacyDirectory.path}${Platform.pathSeparator}hydrated_box.hive').writeAsString('state');
      await File('${legacyDirectory.path}${Platform.pathSeparator}.hydrated_bloc.json').writeAsString('{"UserCubit":"{}"}');
      await File('${legacyDirectory.path}${Platform.pathSeparator}hydrated_box.lock').writeAsString('lock');

      await debugMigrateHydratedStorageDirectory(
        legacyDirectory: legacyDirectory,
        targetDirectory: targetDirectory,
      );

      expect(File('${targetDirectory.path}${Platform.pathSeparator}hydrated_box.hive').readAsStringSync(), 'state');
      expect(File('${targetDirectory.path}${Platform.pathSeparator}.hydrated_bloc.json').existsSync(), isTrue);
      expect(File('${targetDirectory.path}${Platform.pathSeparator}hydrated_box.lock').existsSync(), isFalse);
    });

    test('does not overwrite existing durable hydrated state', () async {
      await targetDirectory.create(recursive: true);
      await File('${targetDirectory.path}${Platform.pathSeparator}hydrated_box.hive').writeAsString('current');
      await File('${legacyDirectory.path}${Platform.pathSeparator}hydrated_box.hive').writeAsString('legacy');

      await debugMigrateHydratedStorageDirectory(
        legacyDirectory: legacyDirectory,
        targetDirectory: targetDirectory,
      );

      expect(File('${targetDirectory.path}${Platform.pathSeparator}hydrated_box.hive').readAsStringSync(), 'current');
    });
  });
}
