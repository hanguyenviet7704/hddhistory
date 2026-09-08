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

    /// Layout thân paywall (xem [PaywallBodyVariant]). Ở cấp config chứ không
    /// theo locale: một config mà tiếng Việt hiện bảng còn tiếng Anh hiện danh
    /// sách là lỗi. Mặc định `benefits` = hành vi đang chạy.
    @Default(PaywallBodyVariant.benefits) PaywallBodyVariant bodyVariant,
    PaywallSaleStrategyEntity? saleStrategy,

    /// The gift popup's schedule (the popup itself opens the compact paywall).
    /// Null when no campaign is configured — every config published before it
    /// existed.
    PaywallGiftCampaignEntity? giftCampaign,

    /// Win-back: closed the FULL paywall without buying → the compact sheet a
    /// few seconds later. Defaults to disabled so every config published before
    /// it existed behaves exactly as it did.
    @Default(PaywallWinBackEntity()) PaywallWinBackEntity winBack,

    /// The laurel + store-rating strip under the plans. Defaults to SHOWN so
    /// configs published before the switch existed keep the build's behaviour;
    /// hiding a marketing claim is the change that has to be asked for.
    @Default(true) bool showCredibilityBlock,

    /// The compact sheet's own headline number ("N% OFF"). Display only — the
    /// charge is the compact SKU's price. Sale events never touch this sheet.
    @Default(0) int compactDiscountPercent,

    /// The compact sheet's urgency line ("You will never see this again…").
    /// Empty falls back to the bundled copy; shown with the discount headline.
    @Default(BaseMultiLanguage()) BaseMultiLanguage compactUrgencyLine,

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

  /// True while a sale event is switched on and [nowUtc] sits inside its
  /// window. Enabled and in-window is all it takes — `appliesTo` is not
  /// consulted (there is one audience; see [ResolvePaywallStrategyUsecase]).
  ///
  /// It lives here rather than staying private to the resolver because a
  /// running sale now silences the compact surfaces as well: the gift popup,
  /// the win-back and the resolver each have to reach the same verdict, and
  /// three copies of this arithmetic would drift the moment one of them was
  /// fixed alone.
  bool hasActiveSaleEventAt(DateTime nowUtc) {
    final event = saleStrategy?.saleEvent;
    if (event == null || !event.enabled || event.startAtUtc == null || event.endAtUtc == null) return false;
    final now = nowUtc.toUtc();
    return !now.isBefore(event.startAtUtc!) && !now.isAfter(event.endAtUtc!);
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

/// Win-back gate. See `PaywallWinBackDto` on the API for the authored shape.
@freezed
abstract class PaywallWinBackEntity with _$PaywallWinBackEntity {
  const factory PaywallWinBackEntity({
    @Default(false) bool enabled,

    /// Seconds between the paywall closing and the compact sheet opening.
    @Default(3) int delaySeconds,

    /// How many times this may fire per app session.
    @Default(1) int maxPerSession,
  }) = _PaywallWinBackEntity;

  factory PaywallWinBackEntity.fromJson(Map<String, dynamic> json) => _$PaywallWinBackEntityFromJson(json);
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

/// Khối nằm giữa header và các thẻ gói trên paywall.
///
/// `benefits` là danh sách lợi ích đang chạy (design `6b · Premium` Version 1),
/// `comparison` là bảng Miễn phí vs Premium (Version 2). Hai kiểu LOẠI TRỪ nhau
/// — design gate chúng ở hai nhánh riêng, hiện cả hai là nói cùng một chuyện
/// hai lần trên một màn.
enum PaywallBodyVariant { benefits, comparison }

@freezed
abstract class PaywallContentEntity with _$PaywallContentEntity {
  const factory PaywallContentEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subheading,
    @Default([]) List<PaywallBenefitEntity> benefits,
    @Default([]) List<PaywallComparisonRowEntity> comparison,
  }) = _PaywallContentEntity;

  factory PaywallContentEntity.fromJson(Map<String, dynamic> json) => _$PaywallContentEntityFromJson(json);
}

/// Một dòng của bảng Miễn phí vs Premium.
@freezed
abstract class PaywallComparisonRowEntity with _$PaywallComparisonRowEntity {
  const factory PaywallComparisonRowEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage free,
    @Default(BaseMultiLanguage()) BaseMultiLanguage premium,
    /// Ô Premium có icon tick trước chữ hay không. Mặc định true vì mọi dòng
    /// trong design đều có tick — dòng lưu thiếu field phải trông như design.
    @Default(true) bool hasCheck,
  }) = _PaywallComparisonRowEntity;

  factory PaywallComparisonRowEntity.fromJson(Map<String, dynamic> json) => _$PaywallComparisonRowEntityFromJson(json);
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

/// How often the app-open trigger may fire. Refines [PaywallGiftCampaignEntity.triggerOnDailyOpen]
/// rather than replacing it: the toggle still says whether the app-open popup
/// runs at all, this says how often.
enum GiftOpenFrequency {
  /// The original schedule: first app open of each local day, days
  /// 1..windowDays, and only once day zero (the first habit) has happened.
  @JsonValue('oncePerDay')
  oncePerDay,

  /// Every app open, for every non-premium reader, from their first one,
  /// indefinitely — no day zero, no window. Throttled only by
  /// [PaywallGiftCampaignEntity.minGapMinutes].
  @JsonValue('everyOpen')
  everyOpen,
}

/// The gift popup. It opens the compact paywall on a schedule that is now
/// config (day 0, plus the app-open trigger — see [GiftOpenFrequency]), so the
/// config carries the switch, an optional title, and those schedule knobs; an
/// empty title falls back to the app's bundled copy.
@freezed
abstract class PaywallGiftCampaignEntity with _$PaywallGiftCampaignEntity {
  const factory PaywallGiftCampaignEntity({
    @Default(false) bool enabled,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,

    /// How many days after day zero the daily-open popup keeps running. The
    /// default is the number this used to hardcode, so a config written before
    /// the field existed behaves exactly as before. Unread when
    /// [openFrequency] is [GiftOpenFrequency.everyOpen] — that mode has no
    /// window and does not count from day zero.
    @Default(7) int windowDays,

    /// The two triggers, switchable independently — a run can want the day-0
    /// moment without the daily reminder, or the reverse. Both default ON,
    /// which is what the app did before they existed.
    @Default(true) bool triggerOnFirstHabit,
    @Default(true) bool triggerOnDailyOpen,

    /// Defaults to the original schedule, so a config written before this
    /// field — and this build reading one — behaves exactly as before.
    @Default(GiftOpenFrequency.oncePerDay) GiftOpenFrequency openFrequency,

    /// Minutes that must pass since the popup last went up before
    /// [GiftOpenFrequency.everyOpen] may show it again. Read ONLY in that mode;
    /// `oncePerDay` has the calendar day as its own gap.
    ///
    /// It exists because the app-open check runs on every `resumed` lifecycle
    /// event, not just a cold start (see `GiftPopupHost`): without it, a reader
    /// who leaves for ten seconds to answer a message comes back to a paywall
    /// popup. 0 means literally every resume.
    @Default(30) int minGapMinutes,
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
  static PaywallGiftCampaignEntity? _giftCampaign(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    if (!_boolValue(value['enabled'])) return null;

    final title = value['title'];
    // Out of range, wrong type or absent all fall back to 7 rather than
    // disabling the window: a bad number in config must not silently switch a
    // running campaign off.
    final rawWindow = value['windowDays'];
    final windowDays = rawWindow is int && rawWindow >= 1 && rawWindow <= 30 ? rawWindow : 7;
    // Same rule as windowDays, for the same reason: anything unexpected —
    // absent, a typo, a mode a later admin build invented — falls back to the
    // original schedule rather than to the more aggressive one. A config we
    // cannot read must never escalate how often the reader is upsold.
    final rawFrequency = value['openFrequency'];
    final openFrequency = rawFrequency == 'everyOpen' ? GiftOpenFrequency.everyOpen : GiftOpenFrequency.oncePerDay;
    final rawMinGap = value['minGapMinutes'];
    final minGapMinutes = rawMinGap is int && rawMinGap >= 0 && rawMinGap <= 1440 ? rawMinGap : 30;
    return PaywallGiftCampaignEntity(
      enabled: true,
      windowDays: windowDays,
      openFrequency: openFrequency,
      minGapMinutes: minGapMinutes,
      // Absent reads as ON, matching every build that shipped before the
      // toggles existed.
      triggerOnFirstHabit: value['triggerOnFirstHabit'] is bool ? value['triggerOnFirstHabit'] as bool : true,
      triggerOnDailyOpen: value['triggerOnDailyOpen'] is bool ? value['triggerOnDailyOpen'] as bool : true,
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
        bodyVariant: _bodyVariant(decoded['bodyVariant']),
        saleStrategy: _saleStrategy(decoded['saleStrategy']),
        giftCampaign: _giftCampaign(decoded['giftCampaign']),
        winBack: _winBack(decoded['winBack']),
        // Absent reads as SHOWN, matching the build that introduced the strip.
        showCredibilityBlock: decoded['showCredibilityBlock'] is bool ? decoded['showCredibilityBlock'] as bool : true,
        reviews: _reviews(decoded['reviews']),
        compactDiscountPercent: decoded['compactPaywall'] is Map<String, dynamic> ? _intValue((decoded['compactPaywall'] as Map<String, dynamic>)['discountPercent']) : 0,
        compactUrgencyLine: _flatLine(decoded['compactPaywall'] is Map<String, dynamic> ? (decoded['compactPaywall'] as Map<String, dynamic>)['urgencyLine'] : null),
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

  /// A missing key parses to disabled, like every gate added after v1.
  ///
  /// `delaySeconds` is clamped rather than rejected: the server already bounds
  /// it 0..60, and a config that somehow carries 900 should still fire — three
  /// seconds late is a worse bug than a minute late. `maxPerSession` floors at 1
  /// because a stored 0 with `enabled: true` reads as "on but never fires",
  /// which looks like a broken feature rather than a disabled one.
  static PaywallWinBackEntity _winBack(Object? value) {
    if (value is! Map<String, dynamic>) return const PaywallWinBackEntity();
    return PaywallWinBackEntity(
      enabled: _boolValue(value['enabled']),
      delaySeconds: _intValue(value['delaySeconds'], fallback: 3).clamp(0, 60),
      maxPerSession: _intValue(value['maxPerSession'], fallback: 1).clamp(1, 5),
    );
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
    final maxComparison = localeMaps.values.map((localeMap) => localeMap['comparison'] is List ? (localeMap['comparison'] as List).length : 0).fold<int>(0, max);
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
      comparison: [
        for (var index = 0; index < maxComparison; index++)
          PaywallComparisonRowEntity(
            label: _rowMultiLanguage(localeMaps, 'comparison', index, 'label'),
            free: _rowMultiLanguage(localeMaps, 'comparison', index, 'free'),
            premium: _rowMultiLanguage(localeMaps, 'comparison', index, 'premium'),
            hasCheck: _rowHasCheck(localeMaps, index),
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

  /// A flat per-locale string map ({en:…, vi:…}) — the shape PaywallGiftTitleDto
  /// and compactPaywall.urgencyLine use, unlike the nested content objects.
  static BaseMultiLanguage _flatLine(Object? value) {
    if (value is! Map<String, dynamic>) return const BaseMultiLanguage();
    return BaseMultiLanguage(
      en: _stringValue(value['en']),
      vi: _stringValue(value['vi']),
      zh: _stringValue(value['zh']),
      ja: _stringValue(value['ja']),
      ko: _stringValue(value['ko']),
    );
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

  /// Ghép một field của dòng thứ [index] trong list [listKey] thành
  /// [BaseMultiLanguage].
  ///
  /// Cùng thủ thuật index-per-locale mà [_benefitMultiLanguage] dùng, chỉ khác là
  /// tên list truyền vào: config lưu MỖI locale một mảng riêng, còn app cần MỘT
  /// mảng dòng mà mỗi ô là đa ngữ. Vị trí trong mảng là thứ duy nhất nối các
  /// locale lại với nhau — nên thêm hay xoá một dòng ở một locale mà không làm ở
  /// locale khác sẽ lệch nội dung, đúng như benefits đã vậy.
  static BaseMultiLanguage _rowMultiLanguage(
    Map<String, Map<String, dynamic>> localeMaps,
    String listKey,
    int index,
    String key,
  ) {
    Object? valueFor(String locale) {
      final rows = localeMaps[locale]?[listKey];
      if (rows is! List || index >= rows.length) return null;
      final row = rows[index];
      return row is Map<String, dynamic> ? row[key] : null;
    }

    return BaseMultiLanguage(
      en: _stringValue(valueFor('en')),
      vi: _stringValue(valueFor('vi')),
      zh: _stringValue(valueFor('zh')),
      ja: _stringValue(valueFor('ja')),
      ko: _stringValue(valueFor('ko')),
    );
  }

  /// `hasCheck` của dòng thứ [index].
  ///
  /// Không đa ngữ được: nó là quyết định hiển thị, và một dòng có tick ở tiếng
  /// Anh nhưng không có ở tiếng Việt là lỗi chứ không phải bản địa hoá. Đọc theo
  /// thứ tự ưu tiên en → các locale còn lại, mặc định TRUE khi không locale nào
  /// nói gì — vì mọi dòng trong design đều có tick.
  static bool _rowHasCheck(Map<String, Map<String, dynamic>> localeMaps, int index) {
    for (final locale in _locales) {
      final rows = localeMaps[locale]?['comparison'];
      if (rows is! List || index >= rows.length) continue;
      final row = rows[index];
      if (row is Map<String, dynamic> && row['hasCheck'] is bool) {
        return row['hasCheck'] as bool;
      }
    }
    return true;
  }

  static PaywallBodyVariant _bodyVariant(Object? value) {
    // Giá trị lạ (bản app cũ hơn một variant mới thêm) rơi về benefits chứ không
    // throw: paywall vẫn phải mở được, và benefits là thứ mọi bản đều render.
    return value == 'comparison' ? PaywallBodyVariant.comparison : PaywallBodyVariant.benefits;
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
