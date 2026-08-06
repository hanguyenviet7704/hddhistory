part of '../services.dart';

/// Sets up the on-disk store every `HydratedCubit` in the app writes to.
///
/// ## Why every hydrated cubit here pins its own `storagePrefix`
///
/// A cubit's stored state is keyed by `storagePrefix`, which `hydrated_bloc`
/// defaults to `runtimeType.toString()`. Release builds are compiled with
/// `--obfuscate` (see `tools/macos/build/build_apk.sh` and `build_ipa.sh`), and
/// obfuscation renames classes — so the key is not `'UserCubit'` but whatever
/// short string the compiler assigned it in THAT build.
///
/// Those assignments are re-derived from the whole program every time, so an
/// ordinary release shifts them. Measured on two builds of this app differing by
/// about twenty lines: `UserCubit` went `wUb` → `yUb`, and all thirteen hydrated
/// cubits changed, along with 46% of every symbol in the binary.
///
/// The consequence was silent and total. After an update the app looked for
/// `yUb`, the previous build had written `wUb`, and the read came back null —
/// so `UserCubit` rebuilt from `UserState.initial()` with no access token and no
/// refresh token, and a signed-in reader was sent back to the login screen.
/// Nothing had expired and nothing was rejected: the session was still on disk
/// under a key nobody looked for any more. Themes, locale, study theme, streak
/// and reading preferences went the same way.
///
/// It could also collide rather than merely miss — `HapticSettingCubit` drew
/// `qVb` in the second build, which was `ThemeCubit`'s key in the first, so it
/// read a blob written for another cubit entirely.
///
/// Pinning each prefix to a literal is what makes the key survive a release. The
/// literals must therefore stay hardcoded and stay put: renaming the Dart class
/// is now free, but changing the string abandons that cubit's stored state.
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
