part of '../../common.dart';

/// Which of a strategy's two SKU lists the paywall renders.
///
/// The strategy still owns the copy and both lists; the entry point the paywall
/// was opened from only picks between them. See [PaywallConfigEntity.entryPointVariants].
enum PaywallProductVariant {
  @JsonValue('full')
  full,
  @JsonValue('compact')
  compact,
}

@freezed
abstract class PaywallConfigEntity with _$PaywallConfigEntity {
  const factory PaywallConfigEntity({
    @Default(1) int schemaVersion,
    @Default(false) bool enableLessonLock,
    @Default(0) int lessonLock,
    @Default(PaywallAutoOpenEntity()) PaywallAutoOpenEntity autoOpen,
    @Default(PaywallInLessonEntity()) PaywallInLessonEntity inLessonPaywall,

    /// Entry-point name (`PaywallEntryPoint.name`) → which SKU list it renders.
    ///
    /// Keyed by raw `String` rather than the enum so this layer stays free of
    /// `monetization`, which is what depends on `common`, not the other way
    /// round. Missing keys read as [PaywallProductVariant.full] — see
    /// [PaywallConfigEntityX.variantForEntryPoint].
    @Default({}) Map<String, PaywallProductVariant> entryPointVariants,
    PaywallSaleStrategyEntity? saleStrategy,

    /// The gift popup's schedule (the popup itself opens the compact paywall).
    /// Null when no campaign is configured — every config published before it
    /// existed.
    PaywallGiftCampaignEntity? giftCampaign,

    /// The laurel + store-rating strip under the plans. Defaults to SHOWN so
    /// configs published before the switch existed keep the build's behaviour;
    /// hiding a marketing claim is the change that has to be asked for.
    @Default(true) bool showCredibilityBlock,

    /// Remote "What people say" cards. Empty means the config carries none and
    /// the app's bundled reviews render instead.
    @Default(<PaywallReviewEntity>[]) List<PaywallReviewEntity> reviews,
  }) = _PaywallConfigEntity;

  factory PaywallConfigEntity.fromRawConfig(String rawConfig) => _PaywallConfigParser.parse(rawConfig);

  factory PaywallConfigEntity.fromJson(Map<String, dynamic> json) => _$PaywallConfigEntityFromJson(json);
}

extension PaywallConfigEntityX on PaywallConfigEntity {
  /// The variant configured for [entryPointName], defaulting to
  /// [PaywallProductVariant.full].
  ///
  /// `full` is the default in every unknown case — absent map, absent key,
  /// unrecognised value — because it is the behaviour of every config published
  /// before variants existed. Narrowing someone's plan list is the change that
  /// needs to be asked for explicitly.
  PaywallProductVariant variantForEntryPoint(String entryPointName) {
    return entryPointVariants[entryPointName] ?? PaywallProductVariant.full;
  }
}

@freezed
abstract class PaywallAutoOpenEntity with _$PaywallAutoOpenEntity {
  const factory PaywallAutoOpenEntity({
    @Default(false) bool enabled,
    @Default(0) int sessionRolloutPercent,
  }) = _PaywallAutoOpenEntity;

  factory PaywallAutoOpenEntity.fromJson(Map<String, dynamic> json) => _$PaywallAutoOpenEntityFromJson(json);
}

/// Opens the paywall from inside a keypoint, the moment the reader swipes off
/// the first card. A third, independent gate: `enableLessonLock`/`lessonLock`
/// blocks a lesson before it opens, `autoOpen` fires on Home/Course, and this
/// one fires mid-lesson.
@freezed
abstract class PaywallInLessonEntity with _$PaywallInLessonEntity {
  const factory PaywallInLessonEntity({
    @Default(false) bool enabled,

    /// 1-based position among the course's keypoints in roadmap order (lesson
    /// by lesson, keypoints within each lesson in order). 0 = every keypoint.
    ///
    /// Counts KEYPOINTS. It used to count lessons despite the name, which made
    /// a configured value mean something other than what the admin panel said
    /// it did — deliberately NOT the same ordering
    /// [RoadmapEntity.lockedLessonStartIndex] counts in.
    @Default(0) int keypointOrdinal,

    /// Cards the reader may pass before the paywall opens; 1 means it opens on
    /// the move from card 1 to card 2.
    @Default(1) int afterCards,
  }) = _PaywallInLessonEntity;

  factory PaywallInLessonEntity.fromJson(Map<String, dynamic> json) => _$PaywallInLessonEntityFromJson(json);
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

    /// Reduced list rendered where the entry point asks for
    /// [PaywallProductVariant.compact]. Empty means "use [products]" — see
    /// `ResolvePaywallStrategyUsecase`.
    @Default([]) List<PaywallProductReferenceEntity> compactProducts,
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
    @Default([]) List<PaywallProductReferenceEntity> compactProducts,
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
    @Default([]) List<PaywallProductReferenceEntity> compactProducts,
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

/// The gift popup. It opens the compact paywall on a schedule coded in the
/// app (day 0 + days 1-7), so all the config carries is the switch and an
/// optional title; empty title falls back to the app's bundled copy.
@freezed
abstract class PaywallGiftCampaignEntity with _$PaywallGiftCampaignEntity {
  const factory PaywallGiftCampaignEntity({
    @Default(false) bool enabled,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
  }) = _PaywallGiftCampaignEntity;

  factory PaywallGiftCampaignEntity.fromJson(Map<String, dynamic> json) => _$PaywallGiftCampaignEntityFromJson(json);
}

/// One card of the paywall's review carousel. Name and avatar are shown as-is
/// in every locale; only [title] and [body] are localized.
@freezed
abstract class PaywallReviewEntity with _$PaywallReviewEntity {
  const factory PaywallReviewEntity({
    @Default('') String name,
    @Default('') String avatarUrl,
    @Default(5) int rating,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage body,
  }) = _PaywallReviewEntity;

  factory PaywallReviewEntity.fromJson(Map<String, dynamic> json) => _$PaywallReviewEntityFromJson(json);
}

class _PaywallConfigParser {
  static const _locales = ['en', 'vi', 'zh', 'ja', 'ko'];

  /// Absent, malformed, or switched off all parse to null so the caller has
  /// one thing to check. `title` is a flat per-locale map (not the nested
  /// content shape) — see PaywallGiftTitleDto on the API side.
  static PaywallGiftCampaignEntity? _giftCampaign(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    if (!_boolValue(value['enabled'])) return null;

    final title = value['title'];
    return PaywallGiftCampaignEntity(
      enabled: true,
      title: title is Map<String, dynamic>
          ? BaseMultiLanguage(
              en: _stringValue(title['en']),
              vi: _stringValue(title['vi']),
              zh: _stringValue(title['zh']),
              ja: _stringValue(title['ja']),
              ko: _stringValue(title['ko']),
            )
          : const BaseMultiLanguage(),
    );
  }

  static PaywallConfigEntity parse(String rawConfig) {
    try {
      final decoded = jsonDecode(rawConfig);
      if (decoded is! Map<String, dynamic>) return const PaywallConfigEntity();
      return PaywallConfigEntity(
        schemaVersion: _intValue(decoded['schemaVersion'], fallback: 1),
        enableLessonLock: _boolValue(decoded['enableLessonLock']),
        lessonLock: _intValue(decoded['lessonLock']),
        autoOpen: _autoOpen(decoded['autoOpen']),
        inLessonPaywall: _inLessonPaywall(decoded['inLessonPaywall']),
        entryPointVariants: _entryPointVariants(decoded['entryPointVariants']),
        saleStrategy: _saleStrategy(decoded['saleStrategy']),
        giftCampaign: _giftCampaign(decoded['giftCampaign']),
        // Absent reads as SHOWN, matching the build that introduced the strip.
        showCredibilityBlock: decoded['showCredibilityBlock'] is bool ? decoded['showCredibilityBlock'] as bool : true,
        reviews: _reviews(decoded['reviews']),
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

  /// A missing key (any version published before this gate existed) parses to
  /// disabled, and `afterCards` never drops below 1 — 0 would mean "open before
  /// the reader has seen anything", which is the one thing this gate must not do.
  static PaywallInLessonEntity _inLessonPaywall(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallInLessonEntity();
    final ordinal = _intValue(value['keypointOrdinal']);
    final afterCards = _intValue(value['afterCards'], fallback: 1);
    return PaywallInLessonEntity(
      enabled: _boolValue(value['enabled']),
      keypointOrdinal: ordinal < 0 ? 0 : ordinal,
      afterCards: afterCards < 1 ? 1 : afterCards,
    );
  }

  /// Only `'full'`/`'compact'` are kept. An unrecognised value is dropped
  /// rather than guessed at, which leaves the getter returning `full` — the
  /// same, safe answer as a missing key.
  static Map<String, PaywallProductVariant> _entryPointVariants(Object? value) {
    if (value is! Map<String, dynamic>) return const {};
    final variants = <String, PaywallProductVariant>{};
    for (final entry in value.entries) {
      final variant = switch (entry.value) {
        'full' => PaywallProductVariant.full,
        'compact' => PaywallProductVariant.compact,
        _ => null,
      };
      if (variant != null) variants[entry.key] = variant;
    }
    return variants;
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
      compactProducts: _products(value['compactProducts']),
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
      compactProducts: _products(value['compactProducts']),
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
      compactProducts: _products(value['compactProducts']),
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

  /// A card with no readable text in ANY locale is dropped — it would render
  /// as an empty white rectangle in the carousel. Everything else is kept as
  /// published; the widget's locale fallback handles partial translations.
  static List<PaywallReviewEntity> _reviews(Object? value) {
    if (value is! List) return const [];
    final reviews = <PaywallReviewEntity>[];
    for (final raw in value) {
      if (raw is! Map<String, dynamic>) continue;
      final content = raw['content'];
      final localeMaps = {
        for (final locale in _locales)
          locale: content is Map<String, dynamic> && content[locale] is Map<String, dynamic> ? content[locale] as Map<String, dynamic> : const <String, dynamic>{},
      };
      final title = _multiLanguage(localeMaps, 'title');
      final body = _multiLanguage(localeMaps, 'body');
      if (title.text.isEmpty && body.text.isEmpty) continue;

      final rating = _intValue(raw['rating'], fallback: 5);
      reviews.add(
        PaywallReviewEntity(
          name: raw['name'] is String ? raw['name'] as String : '',
          avatarUrl: raw['avatarUrl'] is String ? raw['avatarUrl'] as String : '',
          rating: rating < 1 || rating > 5 ? 5 : rating,
          title: title,
          body: body,
        ),
      );
    }
    return reviews;
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
