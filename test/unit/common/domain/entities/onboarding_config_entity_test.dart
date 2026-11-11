import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('OnboardingConfigEntity', () {
    test('defaults to normal flow on empty value', () {
      final config = OnboardingConfigEntity.fromRawConfig('');

      expect(config.enable, isTrue);
      expect(config.flowType, OnboardingFlowType.normal);
      expect(config.isNormal, isTrue);
    });

    test('defaults to normal flow on invalid json payload', () {
      final config = OnboardingConfigEntity.fromRawConfig('{invalid-json');

      expect(config.enable, isTrue);
      expect(config.flowType, OnboardingFlowType.normal);
      expect(config.isBranching, isFalse);
    });

    test('parses enable flag from Firebase Remote Config payload', () {
      final config = OnboardingConfigEntity.fromRawConfig('{"enable":true,"flowType":"normal"}');

      expect(config.enable, isTrue);
      expect(config.isEnabled, isTrue);
      expect(config.isDisabled, isFalse);
      expect(config.flowType, OnboardingFlowType.normal);
    });

    test('parses disabled onboarding payload safely', () {
      final config = OnboardingConfigEntity.fromRawConfig('{"enable":false,"flowType":"branching"}');

      expect(config.enable, isFalse);
      expect(config.isEnabled, isFalse);
      expect(config.isDisabled, isTrue);
      expect(config.flowType, OnboardingFlowType.branching);
    });

    test('parses false-like enable strings as disabled', () {
      final config = OnboardingConfigEntity.fromRawConfig('{"enable":"false","flowType":"normal"}');

      expect(config.enable, isFalse);
      expect(config.isDisabled, isTrue);
    });

    test('parses branching flowType safely', () {
      final config = OnboardingConfigEntity.fromRawConfig('{"flowType":"branching"}');

      expect(config.enable, isTrue);
      expect(config.flowType, OnboardingFlowType.branching);
      expect(config.isBranching, isTrue);
    });
  });
}
