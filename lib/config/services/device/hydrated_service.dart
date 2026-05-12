part of '../services.dart';

class HydrateBlocService {
  HydrateBlocService._();
  static final HydrateBlocService _instance = HydrateBlocService._();
  static HydrateBlocService get instance => _instance;

  Future<void> initialize() async {
    final storageDirectory = await _resolveStorageDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: storageDirectory,
    );
  }

  Future<HydratedStorageDirectory> _resolveStorageDirectory() async {
    if (kIsWeb) return HydratedStorageDirectory.web;

    final legacyDirectory = await getTemporaryDirectory();
    final supportDirectory = await getApplicationSupportDirectory();
    final targetDirectory = Directory('${supportDirectory.path}${Platform.pathSeparator}hydrated_bloc');
    await debugMigrateHydratedStorageDirectory(
      legacyDirectory: legacyDirectory,
      targetDirectory: targetDirectory,
    );
    return HydratedStorageDirectory(targetDirectory.path);
  }
}

@visibleForTesting
Future<void> debugMigrateHydratedStorageDirectory({
  required Directory legacyDirectory,
  required Directory targetDirectory,
}) async {
  if (!legacyDirectory.existsSync()) return;
  if (legacyDirectory.path == targetDirectory.path) return;

  final hasTargetData = targetDirectory.existsSync() && targetDirectory.listSync().any(_isHydratedStorageFile);
  if (hasTargetData) return;

  final legacyFiles = legacyDirectory.listSync().where(_isHydratedStorageFile).whereType<File>().toList();
  if (legacyFiles.isEmpty) return;

  await targetDirectory.create(recursive: true);
  for (final file in legacyFiles) {
    final fileName = file.uri.pathSegments.last;
    final targetPath = '${targetDirectory.path}${Platform.pathSeparator}$fileName';
    if (File(targetPath).existsSync()) continue;
    await file.copy(targetPath);
  }
}

bool _isHydratedStorageFile(FileSystemEntity entity) {
  if (entity is! File) return false;
  final fileName = entity.uri.pathSegments.last;
  return fileName == '.hydrated_bloc.json' || (fileName.startsWith('hydrated_box.') && !fileName.endsWith('.lock'));
}
