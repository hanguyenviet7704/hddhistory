import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  const resolver = ResolvePaywallStrategyUsecase();
  final now = DateTime.utc(2026, 6, 18, 12);

  ResolvedPaywallStrategyEntity resolve({
    PaywallConfigEntity config = _config,
    PaymentPlatform platform = PaymentPlatform.google,
    DateTime? installTime,
    int storedImpressionCount = 0,
    DateTime? nowUtc,
  }) {
    return resolver(
      ResolvePaywallStrategyParams(
        config: config,
        platform: platform,
        nowUtc: nowUtc ?? now,
        installTime: installTime,
        storedImpressionCount: storedImpressionCount,
      ),
    );
  }

  group('ResolvePaywallStrategyUsecase base strategy', () {
    test('Given unknown install time, When resolved, Then selects default user and platform product order', () {
      final google = resolve();
      final apple = resolve(platform: PaymentPlatform.apple);

      expect(google.strategyType, ResolvedPaywallStrategyType.defaultUser);
      expect(google.segment, ResolvedPaywallSegment.defaultUser);
      expect(google.productIds, ['google-default-1', 'google-default-2']);
      expect(apple.productIds, ['apple-default-1', 'apple-default-2']);
      expect(google.isValid, isTrue);
      expect(google.signature, isNotEmpty);
      expect(resolve().signature, google.signature);
    });

    test('Given D0 and D6 installs, When window is seven days, Then selects new-user strategy', () {
      for (final installTime in [DateTime(2026, 6, 18, 23), DateTime(2026, 6, 12, 1)]) {
        final result = resolve(installTime: installTime);

        expect(result.segment, ResolvedPaywallSegment.newUser);
        expect(result.strategyType, ResolvedPaywallStrategyType.newUser);
      }
    });

    test('Given D7, future, or null install time, When resolved, Then selects default user', () {
      for (final installTime in <DateTime?>[DateTime(2026, 6, 11), DateTime(2026, 6, 19), null]) {
        expect(resolve(installTime: installTime).segment, ResolvedPaywallSegment.defaultUser);
      }
    });

    test('Given disabled new-user strategy, When a new user resolves, Then falls back to default user', () {
      final config = _config.copyWith(
        saleStrategy: _config.saleStrategy!.copyWith(
          newUser: _config.saleStrategy!.newUser.copyWith(enabled: false),
        ),
      );

      final result = resolve(config: config, installTime: now);

      expect(result.strategyType, ResolvedPaywallStrategyType.defaultUser);
      expect(result.segment, ResolvedPaywallSegment.newUser);
    });
  });

  group('ResolvePaywallStrategyUsecase impression rules', () {
    test('Given unordered rules, When resolving impressions one, two, and three-plus, Then highest eligible threshold wins', () {
      final first = resolve(installTime: now, storedImpressionCount: 0);
      final second = resolve(installTime: now, storedImpressionCount: 1);
      final later = resolve(installTime: now, storedImpressionCount: 9);

      expect((first.impressionNumber, first.ruleThreshold), (1, 1));
      expect(first.productIds, ['google-new-1']);
      expect((second.impressionNumber, second.ruleThreshold), (2, 2));
      expect(second.productIds, ['google-new-2']);
      expect((later.impressionNumber, later.ruleThreshold), (10, 3));
      expect(later.productIds, ['google-new-3']);
      expect(later.content.heading.en, 'Rule three');
      expect(later.content.benefits, _config.saleStrategy!.newUser.content.benefits);
      expect(_config.saleStrategy!.newUser.impressionRules.first.fromImpression, 3);
    });

    test('Given no matched rule, When resolving a new user, Then returns invalid rather than broadening scope', () {
      final config = _config.copyWith(
        saleStrategy: _config.saleStrategy!.copyWith(
          newUser: _config.saleStrategy!.newUser.copyWith(
            impressionRules: [
              _config.saleStrategy!.newUser.impressionRules.first.copyWith(fromImpression: 2),
            ],
          ),
        ),
      );

      final result = resolve(config: config, installTime: now);

      expect(result.isValid, isFalse);
      expect(result.strategyType, ResolvedPaywallStrategyType.invalid);
      expect(result.productIds, isEmpty);
    });

    test('Given blank or duplicate selected platform IDs, When resolved, Then returns invalid', () {
      for (final products in [
        const [PaywallProductReferenceEntity(appleProductId: 'apple', googleProductId: '')],
        const [
          PaywallProductReferenceEntity(appleProductId: 'apple-1', googleProductId: 'duplicate'),
          PaywallProductReferenceEntity(appleProductId: 'apple-2', googleProductId: 'duplicate'),
        ],
      ]) {
        final config = _config.copyWith(
          saleStrategy: _config.saleStrategy!.copyWith(
            defaultUser: _config.saleStrategy!.defaultUser.copyWith(products: products),
          ),
        );

        expect(resolve(config: config).isValid, isFalse);
      }
    });
  });

  group('ResolvePaywallStrategyUsecase sale event', () {
    test('Given an applicable active event, When at either UTC boundary, Then sale event wins inclusively', () {
      for (final instant in [DateTime.utc(2026, 6, 20), DateTime.utc(2026, 6, 30, 23, 59, 59)]) {
        final result = resolve(config: _eventConfig(), nowUtc: instant);

        expect(result.strategyType, ResolvedPaywallStrategyType.saleEvent);
        expect(result.campaignId, 'summer');
        expect(result.endAtUtc, DateTime.utc(2026, 6, 30, 23, 59, 59));
        expect(result.productIds, ['google-event']);
      }
    });

    test('Given an active event for another segment, When resolved, Then base strategy wins', () {
      final event = _eventConfig().saleStrategy!.saleEvent!;
      final config = _eventConfig().copyWith(
        saleStrategy: _eventConfig().saleStrategy!.copyWith(
          saleEvent: event.copyWith(appliesTo: [PaywallAudienceSegment.newUser]),
        ),
      );

      final result = resolve(config: config, nowUtc: DateTime.utc(2026, 6, 25));

      expect(result.strategyType, ResolvedPaywallStrategyType.defaultUser);
    });
  });
}

const _content = PaywallContentEntity(
  heading: BaseMultiLanguage(en: 'Default heading'),
  subheading: BaseMultiLanguage(en: 'Default subheading'),
  benefits: [
    PaywallBenefitEntity(
      icon: BaseMultiLanguage(en: 'icon'),
      title: BaseMultiLanguage(en: 'benefit'),
    ),
  ],
);

const _config = PaywallConfigEntity(
  schemaVersion: 2,
  saleStrategy: PaywallSaleStrategyEntity(
    defaultUser: PaywallDefaultUserStrategyEntity(
      content: _content,
      products: [
        PaywallProductReferenceEntity(appleProductId: 'apple-default-1', googleProductId: 'google-default-1'),
        PaywallProductReferenceEntity(appleProductId: 'apple-default-2', googleProductId: 'google-default-2'),
      ],
    ),
    newUser: PaywallNewUserStrategyEntity(
      enabled: true,
      windowDays: 7,
      content: PaywallContentEntity(
        benefits: [
          PaywallBenefitEntity(
            icon: BaseMultiLanguage(en: 'icon'),
            title: BaseMultiLanguage(en: 'benefit'),
          ),
        ],
      ),
      impressionRules: [
        PaywallImpressionRuleEntity(
          fromImpression: 3,
          content: PaywallContentEntity(heading: BaseMultiLanguage(en: 'Rule three')),
          products: [PaywallProductReferenceEntity(appleProductId: 'apple-new-3', googleProductId: 'google-new-3')],
        ),
        PaywallImpressionRuleEntity(
          fromImpression: 1,
          content: PaywallContentEntity(heading: BaseMultiLanguage(en: 'Rule one')),
          products: [PaywallProductReferenceEntity(appleProductId: 'apple-new-1', googleProductId: 'google-new-1')],
        ),
        PaywallImpressionRuleEntity(
          fromImpression: 2,
          content: PaywallContentEntity(heading: BaseMultiLanguage(en: 'Rule two')),
          products: [PaywallProductReferenceEntity(appleProductId: 'apple-new-2', googleProductId: 'google-new-2')],
        ),
      ],
    ),
  ),
);

PaywallConfigEntity _eventConfig() {
  return _config.copyWith(
    saleStrategy: _config.saleStrategy!.copyWith(
      saleEvent: PaywallSaleEventStrategyEntity(
        enabled: true,
        campaignId: 'summer',
        startAtUtc: DateTime.utc(2026, 6, 20),
        endAtUtc: DateTime.utc(2026, 6, 30, 23, 59, 59),
        appliesTo: const [PaywallAudienceSegment.defaultUser, PaywallAudienceSegment.newUser],
        content: _content,
        products: const [
          PaywallProductReferenceEntity(appleProductId: 'apple-event', googleProductId: 'google-event'),
        ],
      ),
    ),
  );
}
