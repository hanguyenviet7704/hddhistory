import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldEnsureProfileReload', () {
    ProfileState stateWith({
      String userId = '',
      ProfileStatus status = ProfileStatus.initial,
    }) {
      return ProfileState(
        status: status,
        user: UserEntity(id: userId),
      );
    }

    test('true when the user identity is blank (failed/never-ran load)', () {
      expect(shouldEnsureProfileReload(stateWith()), isTrue);
      expect(
        shouldEnsureProfileReload(stateWith(status: ProfileStatus.failure)),
        isTrue,
      );
    });

    test('true when the last load failed, even with an identity already present', () {
      expect(
        shouldEnsureProfileReload(stateWith(userId: 'user-1', status: ProfileStatus.failure)),
        isTrue,
      );
    });

    test('false while a load is in flight (no duplicate fetch)', () {
      expect(shouldEnsureProfileReload(stateWith(status: ProfileStatus.loading)), isFalse);
      expect(
        shouldEnsureProfileReload(stateWith(userId: 'user-1', status: ProfileStatus.loading)),
        isFalse,
      );
    });

    test('false when identity is present and the last load succeeded (no-op on re-entry)', () {
      expect(
        shouldEnsureProfileReload(stateWith(userId: 'user-1', status: ProfileStatus.success)),
        isFalse,
      );
    });
  });

  group('normalizeHydratedProfileState', () {
    test('resets a persisted loading status so a blank identity self-heals after restore', () {
      final hydrated = ProfileState(status: ProfileStatus.loading, user: UserEntity());
      final normalized = normalizeHydratedProfileState(hydrated);
      expect(normalized.status, ProfileStatus.initial);
      expect(shouldEnsureProfileReload(normalized), isTrue);
    });

    test('leaves non-loading statuses untouched', () {
      final success = ProfileState(status: ProfileStatus.success, user: UserEntity(id: 'user-1'));
      expect(identical(normalizeHydratedProfileState(success), success), isTrue);
    });
  });
}
