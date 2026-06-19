part of '../../common.dart';

@freezed
abstract class PaywallConfigEntity with _$PaywallConfigEntity {
  const factory PaywallConfigEntity({
    @Default(1) int schemaVersion,
    @Default(false) bool enableLessonLock,
    @Default(0) int lessonLock,
    @Default(PaywallAutoOpenEntity()) PaywallAutoOpenEntity autoOpen,
    PaywallSaleStrategyEntity? saleStrategy,
  }) = _PaywallConfigEntity;

  factory PaywallConfigEntity.fromRawConfig(String rawConfig) => _PaywallConfigParser.parse(rawConfig);

  factory PaywallConfigEntity.fromJson(Map<String, dynamic> json) => _$PaywallConfigEntityFromJson(json);
}

@freezed
abstract class PaywallAutoOpenEntity with _$PaywallAutoOpenEntity {
  const factory PaywallAutoOpenEntity({
    @Default(false) bool enabled,
    @Default(0) int sessionRolloutPercent,
  }) = _PaywallAutoOpenEntity;

  factory PaywallAutoOpenEntity.fromJson(Map<String, dynamic> json) => _$PaywallAutoOpenEntityFromJson(json);
}

@freezed
abstract class PaywallSaleStrategyEntity with _$PaywallSaleStrategyEntity {
  const factory PaywallSaleStrategyEntity({
    @Default(PaywallDefaultUserStrategyEntity()) PaywallDefaultUserStrategyEntity defaultUser,
    @Default(PaywallNewUserStrategyEntity()) PaywallNewUserStrategyEntity newUser,
    PaywallSaleEventStrategyEntity? saleEvent,
  }) = _PaywallSaleStrategyEntity;

  factory PaywallSaleStrategyEntity.fromJson(Map<String, dynamic> json) => _$PaywallSaleStrategyEntityFromJson(json);
}

@freezed
abstract class PaywallDefaultUserStrategyEntity with _$PaywallDefaultUserStrategyEntity {
  const factory PaywallDefaultUserStrategyEntity({
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default([]) List<PaywallProductReferenceEntity> products,
  }) = _PaywallDefaultUserStrategyEntity;

  factory PaywallDefaultUserStrategyEntity.fromJson(Map<String, dynamic> json) => _$PaywallDefaultUserStrategyEntityFromJson(json);
}

@freezed
abstract class PaywallNewUserStrategyEntity with _$PaywallNewUserStrategyEntity {
  const factory PaywallNewUserStrategyEntity({
    @Default(false) bool enabled,
    @Default(0) int windowDays,
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default([]) List<PaywallImpressionRuleEntity> impressionRules,
  }) = _PaywallNewUserStrategyEntity;

  factory PaywallNewUserStrategyEntity.fromJson(Map<String, dynamic> json) => _$PaywallNewUserStrategyEntityFromJson(json);
}

@freezed
abstract class PaywallImpressionRuleEntity with _$PaywallImpressionRuleEntity {
  const factory PaywallImpressionRuleEntity({
    @Default(0) int fromImpression,
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default([]) List<PaywallProductReferenceEntity> products,
  }) = _PaywallImpressionRuleEntity;

  factory PaywallImpressionRuleEntity.fromJson(Map<String, dynamic> json) => _$PaywallImpressionRuleEntityFromJson(json);
}

@freezed
abstract class PaywallSaleEventStrategyEntity with _$PaywallSaleEventStrategyEntity {
  const factory PaywallSaleEventStrategyEntity({
    @Default(false) bool enabled,
    @Default('') String campaignId,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    @Default([]) List<PaywallAudienceSegment> appliesTo,
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default([]) List<PaywallProductReferenceEntity> products,
  }) = _PaywallSaleEventStrategyEntity;

  factory PaywallSaleEventStrategyEntity.fromJson(Map<String, dynamic> json) => _$PaywallSaleEventStrategyEntityFromJson(json);
}

@freezed
abstract class PaywallContentEntity with _$PaywallContentEntity {
  const factory PaywallContentEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subheading,
    @Default([]) List<PaywallBenefitEntity> benefits,
  }) = _PaywallContentEntity;

  factory PaywallContentEntity.fromJson(Map<String, dynamic> json) => _$PaywallContentEntityFromJson(json);
}

@freezed
abstract class PaywallBenefitEntity with _$PaywallBenefitEntity {
  const factory PaywallBenefitEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
  }) = _PaywallBenefitEntity;

  factory PaywallBenefitEntity.fromJson(Map<String, dynamic> json) => _$PaywallBenefitEntityFromJson(json);
}

@freezed
abstract class PaywallProductReferenceEntity with _$PaywallProductReferenceEntity {
  const factory PaywallProductReferenceEntity({
    @Default('') String appleProductId,
    @Default('') String googleProductId,
  }) = _PaywallProductReferenceEntity;

  factory PaywallProductReferenceEntity.fromJson(Map<String, dynamic> json) => _$PaywallProductReferenceEntityFromJson(json);
}

enum PaywallAudienceSegment {
  @JsonValue('defaultUser')
  defaultUser,
  @JsonValue('newUser')
  newUser,
}

class _PaywallConfigParser {
  static const _locales = ['en', 'vi', 'zh', 'ja', 'ko'];

  static PaywallConfigEntity parse(String rawConfig) {
    try {
      final decoded = jsonDecode(rawConfig);
      if (decoded is! Map<String, dynamic>) return const PaywallConfigEntity();
      return PaywallConfigEntity(
        schemaVersion: _intValue(decoded['schemaVersion'], fallback: 1),
        enableLessonLock: _boolValue(decoded['enableLessonLock']),
        lessonLock: _intValue(decoded['lessonLock']),
        autoOpen: _autoOpen(decoded['autoOpen']),
        saleStrategy: _saleStrategy(decoded['saleStrategy']),
      );
    } catch (_) {
      return const PaywallConfigEntity();
    }
  }

  static PaywallAutoOpenEntity _autoOpen(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallAutoOpenEntity();
    final rawPercent = value['sessionRolloutPercent'];
    final percent = _intValue(rawPercent);
    final enabled = _boolValue(value['enabled']) && rawPercent is int && percent >= 0 && percent <= 100;
    return PaywallAutoOpenEntity(enabled: enabled, sessionRolloutPercent: percent);
  }

  static PaywallSaleStrategyEntity? _saleStrategy(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return PaywallSaleStrategyEntity(
      defaultUser: _defaultUser(value['defaultUser']),
      newUser: _newUser(value['newUser']),
      saleEvent: _saleEvent(value['saleEvent']),
    );
  }

  static PaywallDefaultUserStrategyEntity _defaultUser(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallDefaultUserStrategyEntity();
    return PaywallDefaultUserStrategyEntity(
      content: _content(value['content']),
      products: _products(value['products']),
    );
  }

  static PaywallNewUserStrategyEntity _newUser(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallNewUserStrategyEntity();
    final rules = value['impressionRules'];
    return PaywallNewUserStrategyEntity(
      enabled: _boolValue(value['enabled']),
      windowDays: _intValue(value['windowDays']),
      content: _content(value['content']),
      impressionRules: rules is List ? rules.map(_impressionRule).toList() : const [],
    );
  }

  static PaywallImpressionRuleEntity _impressionRule(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallImpressionRuleEntity();
    return PaywallImpressionRuleEntity(
      fromImpression: _intValue(value['fromImpression']),
      content: _content(value['content']),
      products: _products(value['products']),
    );
  }

  static PaywallSaleEventStrategyEntity? _saleEvent(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final startAtUtc = _dateTimeUtc(value['startAtUtc']);
    final endAtUtc = _dateTimeUtc(value['endAtUtc']);
    if (startAtUtc == null || endAtUtc == null || startAtUtc.isAfter(endAtUtc)) return null;
    final appliesTo = value['appliesTo'];
    return PaywallSaleEventStrategyEntity(
      enabled: _boolValue(value['enabled']),
      campaignId: _stringValue(value['campaignId']),
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc,
      appliesTo: appliesTo is List ? appliesTo.map(_segment).nonNulls.toList() : const [],
      content: _content(value['content']),
      products: _products(value['products']),
    );
  }

  static PaywallContentEntity _content(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallContentEntity();
    final localeMaps = {
      for (final locale in _locales) locale: value[locale] is Map<String, dynamic> ? value[locale] as Map<String, dynamic> : const <String, dynamic>{},
    };
    final maxBenefits = localeMaps.values.map((localeMap) => localeMap['benefits'] is List ? (localeMap['benefits'] as List).length : 0).fold<int>(0, max);
    return PaywallContentEntity(
      heading: _multiLanguage(localeMaps, 'heading'),
      subheading: _multiLanguage(localeMaps, 'subheading'),
      benefits: [
        for (var index = 0; index < maxBenefits; index++)
          PaywallBenefitEntity(
            icon: _benefitMultiLanguage(localeMaps, index, 'icon'),
            title: _benefitMultiLanguage(localeMaps, index, 'title'),
          ),
      ],
    );
  }

  static List<PaywallProductReferenceEntity> _products(Object? value) {
    if (value is! List) return const [];
    return value.map((item) {
      if (item is! Map<String, dynamic>) return const PaywallProductReferenceEntity();
      return PaywallProductReferenceEntity(
        appleProductId: _stringValue(item['appleProductId']),
        googleProductId: _stringValue(item['googleProductId']),
      );
    }).toList();
  }

  static BaseMultiLanguage _multiLanguage(Map<String, Map<String, dynamic>> localeMaps, String key) {
    return BaseMultiLanguage(
      en: _stringValue(localeMaps['en']?[key]),
      vi: _stringValue(localeMaps['vi']?[key]),
      zh: _stringValue(localeMaps['zh']?[key]),
      ja: _stringValue(localeMaps['ja']?[key]),
      ko: _stringValue(localeMaps['ko']?[key]),
    );
  }

  static BaseMultiLanguage _benefitMultiLanguage(Map<String, Map<String, dynamic>> localeMaps, int index, String key) {
    Object? valueFor(String locale) {
      final benefits = localeMaps[locale]?['benefits'];
      if (benefits is! List || index >= benefits.length) return null;
      final benefit = benefits[index];
      return benefit is Map<String, dynamic> ? benefit[key] : null;
    }

    return BaseMultiLanguage(
      en: _stringValue(valueFor('en')),
      vi: _stringValue(valueFor('vi')),
      zh: _stringValue(valueFor('zh')),
      ja: _stringValue(valueFor('ja')),
      ko: _stringValue(valueFor('ko')),
    );
  }

  static PaywallAudienceSegment? _segment(Object? value) {
    return switch (value) {
      'defaultUser' => PaywallAudienceSegment.defaultUser,
      'newUser' => PaywallAudienceSegment.newUser,
      _ => null,
    };
  }

  static DateTime? _dateTimeUtc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  static bool _boolValue(Object? value) => value is bool && value;

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    return fallback;
  }

  static String _stringValue(Object? value) => value is String ? value.trim() : '';
}
