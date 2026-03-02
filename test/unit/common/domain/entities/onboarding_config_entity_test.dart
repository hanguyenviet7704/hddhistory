import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('OnboardingConfigEntity', () {
    test('defaults to normal flow on empty value', () {
      final config = OnboardingConfigEntity.fromRawConfig('');

      expect(config.flowType, OnboardingFlowType.normal);
      expect(config.isNormal, isTrue);
    });

    test('defaults to normal flow on invalid json payload', () {
      final config = OnboardingConfigEntity.fromRawConfig('{invalid-json');

      expect(config.flowType, OnboardingFlowType.normal);
      expect(config.isBranching, isFalse);
    });

    test('parses branching flowType safely', () {
      final config = OnboardingConfigEntity.fromRawConfig('{"flowType":"branching"}');

      expect(config.flowType, OnboardingFlowType.branching);
      expect(config.isBranching, isTrue);
    });
  });
}
