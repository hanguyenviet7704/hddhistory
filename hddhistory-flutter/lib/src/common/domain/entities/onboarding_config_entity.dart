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
  final bool enable;
  final OnboardingFlowType flowType;

  const OnboardingConfigEntity({
    this.enable = true,
    this.flowType = OnboardingFlowType.normal,
  });

  factory OnboardingConfigEntity.fromJson(Map<String, dynamic> json) {
    return OnboardingConfigEntity(
      enable: _parseEnable(json['enable']),
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

  static bool _parseEnable(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return true;
      return switch (normalized) {
        'false' || '0' || 'off' || 'disable' || 'disabled' || 'no' => false,
        _ => true,
      };
    }
    return true;
  }

  bool get isEnabled => enable;
  bool get isDisabled => !enable;
  bool get isBranching => flowType == OnboardingFlowType.branching;
  bool get isNormal => flowType == OnboardingFlowType.normal;
}
