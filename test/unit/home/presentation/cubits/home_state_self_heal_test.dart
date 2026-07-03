import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldSelfHealHomeData', () {
    HomeState stateWith({
      List<SkillsetEntity> skillsets = const [],
      HomeStatus status = HomeStatus.initial,
    }) {
      return HomeState(
        status: status,
        pageData: BasePageBreak<SkillsetEntity>(items: skillsets),
      );
    }

    test('true when catalog is empty and nothing is loading (failed/skipped first load)', () {
      expect(shouldSelfHealHomeData(stateWith()), isTrue);
      expect(shouldSelfHealHomeData(stateWith(status: HomeStatus.failure)), isTrue);
      // A finished load that came back empty should also retry.
      expect(shouldSelfHealHomeData(stateWith(status: HomeStatus.success)), isTrue);
    });

    test('false while a load is in flight (no duplicate fetch)', () {
      expect(shouldSelfHealHomeData(stateWith(status: HomeStatus.loading)), isFalse);
    });

    test('false when the catalog is already loaded (no-op on normal mounts)', () {
      final loaded = stateWith(
        skillsets: [SkillsetEntity(id: 's1')],
        status: HomeStatus.success,
      );
      expect(shouldSelfHealHomeData(loaded), isFalse);
    });
  });
}
