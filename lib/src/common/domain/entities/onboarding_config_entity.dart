part of '../../common.dart';

enum OnboardingFlowType {
  normal,
  branching
  ;

  static OnboardingFlowType fromRawValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'branching' => OnboardingFlowType.branching,
      'normal' => OnboardingFlowType.normal,
      _ => OnboardingFlowType.normal,
    };
  }
}

class OnboardingConfigEntity {
  final OnboardingFlowType flowType;

  const OnboardingConfigEntity({
    this.flowType = OnboardingFlowType.normal,
  });

  factory OnboardingConfigEntity.fromJson(Map<String, dynamic> json) {
    return OnboardingConfigEntity(
      flowType: OnboardingFlowType.fromRawValue(json['flowType']?.toString()),
    );
  }

  factory OnboardingConfigEntity.fromRawConfig(String rawConfig) {
    if (rawConfig.trim().isEmpty) {
      return const OnboardingConfigEntity();
    }

    try {
      final decoded = jsonDecode(rawConfig);
      if (decoded is Map<String, dynamic>) {
        return OnboardingConfigEntity.fromJson(decoded);
      }
      if (decoded is Map) {
        return OnboardingConfigEntity.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      return const OnboardingConfigEntity();
    } catch (_) {
      return const OnboardingConfigEntity();
    }
  }

  bool get isBranching => flowType == OnboardingFlowType.branching;
  bool get isNormal => flowType == OnboardingFlowType.normal;
}
