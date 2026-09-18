part of '../../onboard_v2.dart';

/// Maps the config-driven [OnboardingContentConfigEntity] — fetched from
/// `GET /onboarding-config` via `GetOnboardingContentConfigUseCase` — onto the
/// [OnboardEntity] shape onboard_v2's pages consume (`onbCopy`,
/// `OnboardV2AgeTextResolver`, the intro carousel).
///
/// A blank/unseeded [config] (first run, offline, backend not seeded yet) maps
/// to an [OnboardEntity] with an empty `age` list and copy entries whose value
/// is blank — `onbCopy` falls back to the bundled l10n default for a blank
/// value, so the flow renders identically either way.
///
/// Onboarding v3 note: `paths`/`symptoms` are NOT mapped anymore. Câu 1/2/3
/// đọc thẳng taxonomy từ DB (`GET /onboarding-taxonomy`), config chỉ còn giữ
/// phần chữ.
///
/// See meup-api/plans/260721-onboard-v2-config-driven/contract.md and
/// meup-api/plans/260918-onboarding-v3-taxonomy/design.md.
abstract final class OnboardV2ConfigMapper {
  static OnboardEntity toOnboardEntity(OnboardingContentConfigEntity config) {
    return OnboardEntity(
      age: _mapAge(config),
      copy: _mapCopy(config),
      intro: _mapIntroDeck(config),
    );
  }

  /// The P1 intro carousel (`OnboardV2IntroCarousel`) renders one card per
  /// `welcome.deck` item. We reuse [OnboardEntity.intro] as the transport
  /// (image + label per card). An item with a blank `imageUrl` (admin left it
  /// empty) falls back to the exact bundled illustration the app shipped for
  /// that path key, so an unseeded/partial deck still renders — and the carousel
  /// only reverts to its own hardcoded deck when there is no config deck at all.
  static List<OnboardIntroEntity> _mapIntroDeck(OnboardingContentConfigEntity config) {
    final deck = [...config.welcome.deck]..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (final item in deck)
        OnboardIntroEntity(
          id: item.order,
          image: item.imageUrl.trim().isNotEmpty ? item.imageUrl.trim() : _bundledDeckAsset(item.key),
          title: item.label,
        ),
    ];
  }

  static String _bundledDeckAsset(String key) => switch (key) {
    'FEEL_BETTER' => AppAsset.images.app.onboardFeelDecor.path,
    'THINK_BETTER' => AppAsset.images.app.onboardThinkDecor.path,
    'WORK_BETTER' => AppAsset.images.app.onboardWorkDecor.path,
    'CONNECT_BETTER' => AppAsset.images.app.onboardConnectDecor.path,
    'LEARN_BETTER' => AppAsset.images.app.onboardLearnDecor.path,
    'EXPLORE_BETTER' => AppAsset.images.app.onboardExploreDeco.path,
    _ => AppAsset.images.app.onboardFeelDecor.path,
  };

  static List<OnboardOptionEntity> _mapAge(OnboardingContentConfigEntity config) {
    final options = config.age.options;
    return [
      for (var i = 0; i < options.length; i++)
        OnboardOptionEntity(
          id: i,
          label: options[i].label,
          title: options[i].label,
          trackingLabel: options[i].key,
        ),
    ];
  }

  /// `titleBrand` is a plain String in the config (not per-locale) — mirrored
  /// into every [BaseMultiLanguage] slot.
  static BaseMultiLanguage _wrapPlainString(String value) => BaseMultiLanguage(en: value, vi: value, zh: value, ja: value, ko: value);

  static List<OnboardCopyEntity> _mapCopy(OnboardingContentConfigEntity config) {
    final welcome = config.welcome;
    final name = config.name;
    final age = config.age;
    final notif = config.notif;
    final pick = config.pick;
    final theme = config.theme;
    return [
      OnboardCopyEntity(key: 'onboardingV2P1TitlePrefix', value: welcome.titlePrefix),
      OnboardCopyEntity(key: 'onboardingV2P1TitleBrand', value: _wrapPlainString(welcome.titleBrand)),
      OnboardCopyEntity(key: 'onboardingV2P1SubtitleLine1', value: welcome.subtitle),
      OnboardCopyEntity(key: 'onboardingV2P1GetStartedCta', value: welcome.ctaLabel),
      // onboardingV2P1SubtitleLine2 has no config source — omit, l10n fallback applies.
      OnboardCopyEntity(key: 'onboardingV2P2HeadingPrefix', value: name.heading),
      OnboardCopyEntity(key: 'onboardingV2P2HeadingHighlight', value: name.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P2Subtitle', value: name.helper),
      OnboardCopyEntity(key: 'onboardingV2P2InputHint', value: name.inputHint),
      // P3 age (headingTemplate keeps its {name} placeholder — the page substitutes it).
      OnboardCopyEntity(key: 'onboardingV2P3HeadingPrefix', value: age.headingTemplate),
      OnboardCopyEntity(key: 'onboardingV2P3HeadingHighlight', value: age.headingHighlight),
      // NOTE: onboardingV2P4Heading*/Subtitle (config.habit) and
      // onboardingV2P5PathHeading*/Subtitle + onboardingV2P5Heading*/Suffix
      // (config.paths/config.brain) used to be mapped here for the retired v2
      // P4/P5 pages. Nothing reads those keys anymore (onboard_v2 v3 uses its
      // own onboardingV3P4/P5* keys — see above) — removed as dead write-only
      // entries rather than left to bit-rot.
      OnboardCopyEntity(key: 'onboardingV2P6HeadingPrefix', value: notif.heading),
      OnboardCopyEntity(key: 'onboardingV2P6HeadingHighlight', value: notif.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P6Subtitle', value: notif.subtitle),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardTitle', value: notif.cardTitle),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardBody', value: notif.cardBody),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardTimestamp', value: notif.cardTimestamp),
      // onboardingV2NotifyCta (from notif.ctaLabel) removed — it was the
      // retired v2 notification-gate screen's CTA copy, wired to the wrong
      // config section. S8's CTA now reads onboardingV3P8Cta below, sourced
      // from `reminder.ctaLabel` (the field the admin Onboarding Config page
      // actually exposes for this screen).
      // P8 course picker (from config.pick).
      OnboardCopyEntity(key: 'onboardingV2P8Eyebrow', value: pick.eyebrow),
      OnboardCopyEntity(key: 'onboardingV2P8Title', value: _concat(pick.heading, pick.headingHighlight)),
      OnboardCopyEntity(key: 'onboardingV2P8Label', value: pick.label),
      // onboardingV2P8SelectCta (also pick.primaryCta) removed — dead,
      // nothing reads it; the result page's CTA reads onboardingV3P10Cta,
      // mapped from the same pick.primaryCta below.
      OnboardCopyEntity(key: 'onboardingV2P8CatalogCta', value: pick.secondaryCta),
      // P9 pick theme (from config.theme).
      OnboardCopyEntity(key: 'onboardingV2P9TitlePrefix', value: theme.titlePrefix),
      OnboardCopyEntity(key: 'onboardingV2P9TitleHighlight', value: theme.titleHighlight),
      OnboardCopyEntity(key: 'onboardingV2P9Subtitle', value: theme.subtitle),
      OnboardCopyEntity(key: 'onboardingV2P9Cta', value: theme.ctaLabel),
      OnboardCopyEntity(key: 'onboardingV2P9Helper', value: theme.helper),

      //* --- Onboarding v3 (11 màn theo taxonomy) ---
      // S4/S5 KHÔNG map nữa: `paths`/`habit` là config của onboarding v2 (câu
      // chữ cũ, không có {name}) và bị seed trên MỌI môi trường — nếu map ở
      // đây, S4/S5 sẽ luôn hiện chữ v2 thay vì bản l10n mới của v3 (đã có
      // {name}), vì `onbCopy` ưu tiên một giá trị config không rỗng. Cả hai
      // trang đều gọi `onbCopy(..., fallback: l10n...)` nên bỏ mapping ở đây
      // là đủ để chúng rơi thẳng về l10n. Có thể thêm field config riêng cho
      // S4/S5 sau nếu BA muốn admin sửa được hai màn này.
      // S6 mong muốn.
      OnboardCopyEntity(key: 'onboardingV3P6HeadingPrefix', value: config.desire.heading),
      OnboardCopyEntity(key: 'onboardingV3P6HeadingHighlight', value: config.desire.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV3P6Helper', value: config.desire.helper),
      // S7 MeUp dạy thế nào.
      OnboardCopyEntity(key: 'onboardingV3P7Eyebrow', value: config.how.eyebrow),
      OnboardCopyEntity(key: 'onboardingV3P7HeadingPrefix', value: config.how.heading),
      OnboardCopyEntity(key: 'onboardingV3P7HeadingHighlight', value: config.how.headingHighlight),
      for (var i = 0; i < config.how.steps.length && i < 4; i++) ...[
        OnboardCopyEntity(key: 'onboardingV3P7Step${i + 1}Title', value: config.how.steps[i].title),
        OnboardCopyEntity(key: 'onboardingV3P7Step${i + 1}Body', value: config.how.steps[i].body),
      ],
      OnboardCopyEntity(key: 'onboardingV3P7Footer', value: config.how.footer),
      OnboardCopyEntity(key: 'onboardingV3P7Cta', value: config.how.ctaLabel),
      // S8 nhắc học. GIỜ của preset không đi đường copy — cubit đọc thẳng
      // `reminder.presets[i].time` vào `state.reminderPresets`.
      OnboardCopyEntity(key: 'onboardingV3P8HeadingPrefix', value: config.reminder.heading),
      OnboardCopyEntity(key: 'onboardingV3P8HeadingHighlight', value: config.reminder.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV3P8Subtitle', value: config.reminder.subtitle),
      OnboardCopyEntity(key: 'onboardingV3P8TimeSectionLabel', value: config.reminder.timeSectionLabel),
      for (var i = 0; i < config.reminder.presets.length && i < 3; i++)
        OnboardCopyEntity(key: 'onboardingV3P8Preset${i + 1}', value: config.reminder.presets[i].label),
      OnboardCopyEntity(key: 'onboardingV3P8Cta', value: config.reminder.ctaLabel),
      OnboardCopyEntity(key: 'onboardingV3P8SecondaryCta', value: config.reminder.secondaryCtaLabel),
      // S9 loading.
      OnboardCopyEntity(key: 'onboardingV3P9HeadingPrefix', value: config.loading.heading),
      OnboardCopyEntity(key: 'onboardingV3P9HeadingHighlight', value: config.loading.headingHighlight),
      for (var i = 0; i < config.loading.lines.length && i < 4; i++)
        OnboardCopyEntity(key: 'onboardingV3P9Line${i + 1}', value: config.loading.lines[i]),
      // S10 kết quả.
      OnboardCopyEntity(key: 'onboardingV3P10Cta', value: pick.primaryCta),
    ];
  }

  /// Joins two [BaseMultiLanguage] values per-locale with a single space,
  /// skipping either side if blank for that locale (e.g. `"Pick your"` +
  /// `"course"` -> `"Pick your course"`). Used where the config splits a
  /// heading across two admin-editable fields but onboard_v2 renders it as
  /// one copy string (P8's title combines `pick.heading` + `pick.headingHighlight`).
  static BaseMultiLanguage _concat(BaseMultiLanguage a, BaseMultiLanguage b) {
    String join(String x, String y) => [x, y].where((s) => s.trim().isNotEmpty).join(' ');
    return BaseMultiLanguage(
      en: join(a.en, b.en),
      vi: join(a.vi, b.vi),
      zh: join(a.zh, b.zh),
      ja: join(a.ja, b.ja),
      ko: join(a.ko, b.ko),
    );
  }
}
