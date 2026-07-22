part of '../../onboard_v2.dart';

/// Maps the config-driven [OnboardingContentConfigEntity] — fetched from
/// `GET /onboarding-config` via `GetOnboardingContentConfigUseCase` — onto the
/// legacy [OnboardEntity] shape that onboard_v2's pages/resolvers already
/// consume (`OnboardV2PathResolver`, `onbCopy`, `OnboardV2AgeTextResolver`,
/// ...). This is the ONLY seam onboard_v2 needed to move off the legacy
/// `/onboardings` module and onto the admin's `onboarding-config` singleton —
/// every page/widget/resolver downstream stays byte-identical.
///
/// A blank/unseeded [config] (first run, offline, backend not seeded yet)
/// maps to an [OnboardEntity] with empty `age`/`paths` and copy entries whose
/// value is blank — `onbCopy` and [OnboardV2PathResolver] both already fall
/// back to the bundled l10n/enum defaults for a blank value, so the flow
/// renders identically either way.
///
/// See meup-api/plans/260721-onboard-v2-config-driven/contract.md.
abstract final class OnboardV2ConfigMapper {
  static OnboardEntity toOnboardEntity(OnboardingContentConfigEntity config) {
    return OnboardEntity(
      age: _mapAge(config),
      paths: _mapPaths(config),
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

  static List<OnboardPathEntity> _mapPaths(OnboardingContentConfigEntity config) {
    return [
      for (final item in config.paths.items)
        OnboardPathEntity(
          key: item.key,
          title: item.label,
          shortTitle: OnboardV2PathResolver.matchPath(item.key)?.shortTitle ?? '',
          iconKey: item.iconKey,
          iconUrl: item.iconUrl,
          trackingLabel: item.key,
          order: item.order,
          symptoms: item.symptoms.isNotEmpty
              ? [
                  for (final symptom in item.symptoms)
                    OnboardSymptomEntity(
                      key: symptom.key,
                      title: symptom.label,
                      trackingLabel: symptom.key,
                      order: symptom.order,
                    ),
                ]
              : _enumSymptomsFor(item.key),
        ),
    ];
  }

  /// Defensive fallback for a config path that carries no symptoms yet (config
  /// deployed/seeded before the `symptoms` field existed, or a partially-filled
  /// path). Derives the bundled enum symptoms for the matching [OnboardingPath]
  /// so the P7 symptom-selection screen — and its course recommendation — is
  /// never empty. Keys stay the enum `trackingId`s, preserving the round-trip
  /// contract. Returns empty only for a path key with no matching enum.
  static List<OnboardSymptomEntity> _enumSymptomsFor(String pathKey) {
    final enumPath = OnboardV2PathResolver.matchPath(pathKey);
    if (enumPath == null) return const [];
    final symptoms = enumPath.symptoms;
    return [
      for (var i = 0; i < symptoms.length; i++)
        OnboardSymptomEntity(
          key: symptoms[i].trackingId,
          title: _wrapPlainString(symptoms[i].title),
          trackingLabel: symptoms[i].trackingId,
          order: i,
        ),
    ];
  }

  /// `titleBrand` is a plain String in the config (not per-locale) — mirrored
  /// into every [BaseMultiLanguage] slot, same pattern as
  /// [OnboardV2PathResolver]'s enum-fallback titles.
  static BaseMultiLanguage _wrapPlainString(String value) => BaseMultiLanguage(en: value, vi: value, zh: value, ja: value, ko: value);

  static List<OnboardCopyEntity> _mapCopy(OnboardingContentConfigEntity config) {
    final welcome = config.welcome;
    final name = config.name;
    final age = config.age;
    final paths = config.paths;
    final brain = config.brain;
    final habit = config.habit;
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
      // P4 symptoms (from config.habit).
      OnboardCopyEntity(key: 'onboardingV2P4HeadingPrefix', value: habit.heading),
      OnboardCopyEntity(key: 'onboardingV2P4HeadingHighlight', value: habit.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P4Subtitle', value: habit.subtitle),
      // P5 path selection.
      OnboardCopyEntity(key: 'onboardingV2P5PathHeadingPrefix', value: paths.heading),
      OnboardCopyEntity(key: 'onboardingV2P5PathHeadingHighlight', value: paths.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P5PathSubtitle', value: paths.helper),
      // P5 path map (from config.brain).
      OnboardCopyEntity(key: 'onboardingV2P5HeadingPrefix', value: brain.heading),
      OnboardCopyEntity(key: 'onboardingV2P5HeadingHighlight', value: brain.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P5HeadingSuffix', value: brain.headingSuffix),
      OnboardCopyEntity(key: 'onboardingV2P6HeadingPrefix', value: notif.heading),
      OnboardCopyEntity(key: 'onboardingV2P6HeadingHighlight', value: notif.headingHighlight),
      OnboardCopyEntity(key: 'onboardingV2P6Subtitle', value: notif.subtitle),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardTitle', value: notif.cardTitle),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardBody', value: notif.cardBody),
      OnboardCopyEntity(key: 'onboardingV2NotificationCardTimestamp', value: notif.cardTimestamp),
      OnboardCopyEntity(key: 'onboardingV2NotifyCta', value: notif.ctaLabel),
      // P8 course picker (from config.pick).
      OnboardCopyEntity(key: 'onboardingV2P8Eyebrow', value: pick.eyebrow),
      OnboardCopyEntity(key: 'onboardingV2P8Title', value: _concat(pick.heading, pick.headingHighlight)),
      OnboardCopyEntity(key: 'onboardingV2P8Label', value: pick.label),
      OnboardCopyEntity(key: 'onboardingV2P8SelectCta', value: pick.primaryCta),
      OnboardCopyEntity(key: 'onboardingV2P8CatalogCta', value: pick.secondaryCta),
      // P9 pick theme (from config.theme).
      OnboardCopyEntity(key: 'onboardingV2P9TitlePrefix', value: theme.titlePrefix),
      OnboardCopyEntity(key: 'onboardingV2P9TitleHighlight', value: theme.titleHighlight),
      OnboardCopyEntity(key: 'onboardingV2P9Subtitle', value: theme.subtitle),
      OnboardCopyEntity(key: 'onboardingV2P9Cta', value: theme.ctaLabel),
      OnboardCopyEntity(key: 'onboardingV2P9Helper', value: theme.helper),
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
