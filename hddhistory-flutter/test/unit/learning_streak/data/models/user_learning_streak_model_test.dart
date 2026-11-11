import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('UserLearningStreakModel sanitization', () {
    test('coerces negative numeric values and invalid weekStudy length', () {
      const model = UserLearningStreakModel(
        studyTime: -10,
        currentStreak: -2,
        bestStreak: -7,
        weekStudy: [true, false],
      );

      final entity = model.toEntity();

      expect(entity.studyTime, 0);
      expect(entity.currentStreak, 0);
      expect(entity.bestStreak, 0);
      expect(entity.weekStudy, kLearningStreakEmptyWeekStudy);
    });

    test('keeps valid values unchanged', () {
      const model = UserLearningStreakModel(
        studyTime: 25,
        currentStreak: 4,
        bestStreak: 9,
        weekStudy: [true, false, true, false, true, false, true],
      );

      final entity = model.toEntity();

      expect(entity.studyTime, 25);
      expect(entity.currentStreak, 4);
      expect(entity.bestStreak, 9);
      expect(entity.weekStudy, [true, false, true, false, true, false, true]);
    });
  });
}
