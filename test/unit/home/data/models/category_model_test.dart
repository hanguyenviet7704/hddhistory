import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('CategoryModel', () {
    test('maps backend onboardingIntroduce wire value to entity enum', () {
      final model = CategoryModel.fromJson({
        '_id': 'category_1',
        'onboardingIntroduce': 'MY_FEELINGS_FEEL_LOUD',
      });

      expect(model.toEntity().onboardingIntroduce, CategoryOnboardingIntroduce.myFeelingsFeelLoud);
    });

    test('keeps unknown onboardingIntroduce values null', () {
      final model = CategoryModel.fromJson({
        '_id': 'category_1',
        'onboardingIntroduce': 'UNKNOWN_VALUE',
      });

      expect(model.toEntity().onboardingIntroduce, isNull);
    });
  });
}
