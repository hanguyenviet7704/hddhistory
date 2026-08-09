import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  const resolver = ResolvePaywallStrategyUsecase();
  final now = DateTime.utc(2026, 6, 18, 12);

  ResolvedPaywallStrategyEntity resolve({
    PaywallConfigEntity config = _config,
    PaymentPlatform platform = PaymentPlatform.google,
    DateTime? nowUtc,
    PaywallEntryPoint entryPoint = PaywallEntryPoint.other,
  }) {
    return resolver(
      ResolvePaywallStrategyParams(
        config: config,
        platform: platform,
        nowUtc: nowUtc ?? now,
        entryPoint: entryPoint,
      ),
    );
  }

  group('ResolvePaywallStrategyUsecase base strategy', () {
    test('Given any reader, When resolved, Then selects default user and platform product order', () {
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

    test('Given raw config that still carries a newUser block, When parsed and resolved, Then it is ignored', () {
      // The new-user segment was removed (2026-08-08). Stored configs written
      // before that still carry the block, so parsing must drop it silently
      // rather than letting it steer anything.
      final config = PaywallConfigEntity.fromRawConfig(jsonEncode({
        'schemaVersion': 2,
        'saleStrategy': {
          'defaultUser': {
            'content': {'en': {'heading': 'Head'}},
            'products': [
              {'appleProductId': 'apple-default-1', 'googleProductId': 'google-default-1'},
            ],
          },
          'newUser': {
            'enabled': true,
            'windowDays': 7,
            'impressionRules': [
              {
                'fromImpression': 1,
                'content': {'en': {'heading': 'Rule one'}},
                'products': [
                  {'appleProductId': 'apple-new-1', 'googleProductId': 'google-new-1'},
                ],
              },
            ],
          },
        },
      }));

      final result = resolve(config: config);

      expect(result.strategyType, ResolvedPaywallStrategyType.defaultUser);
      expect(result.segment, ResolvedPaywallSegment.defaultUser);
      expect(result.productIds, ['google-default-1']);
    });
  });

  group('ResolvePaywallStrategyUsecase product IDs', () {
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

    test('Given an event aimed at any audience, When in window, Then it still wins', () {
      // `appliesTo` no longer gates anything: with one audience left, its only
      // remaining effect was to hide a correctly configured campaign from
      // everybody — which is exactly what happened on dev (2026-08-08).
      for (final audience in PaywallAudienceSegment.values) {
        final event = _eventConfig().saleStrategy!.saleEvent!;
        final config = _eventConfig().copyWith(
          saleStrategy: _eventConfig().saleStrategy!.copyWith(
            saleEvent: event.copyWith(appliesTo: [audience]),
          ),
        );

        final result = resolve(config: config, nowUtc: DateTime.utc(2026, 6, 25));

        expect(result.strategyType, ResolvedPaywallStrategyType.saleEvent);
      }
    });
  });

  group('ResolvePaywallStrategyUsecase entry-point variants', () {
    test('Given a compact entry point, When resolved, Then renders the reduced list', () {
      final result = resolve(config: _compactConfig(), entryPoint: PaywallEntryPoint.inLesson);

      expect(result.variant, PaywallProductVariant.compact);
      expect(result.productIds, ['google-default-compact']);
    });

    test('Given a full entry point, When resolved, Then renders the full list', () {
      final result = resolve(config: _compactConfig(), entryPoint: PaywallEntryPoint.profile);

      expect(result.variant, PaywallProductVariant.full);
      expect(result.productIds, ['google-default-1', 'google-default-2']);
    });

    test('Given an entry point absent from the map, When resolved, Then defaults to the full list', () {
      final result = resolve(config: _compactConfig(), entryPoint: PaywallEntryPoint.habit);

      expect(result.variant, PaywallProductVariant.full);
      expect(result.productIds, ['google-default-1', 'google-default-2']);
    });

    test('Given no entryPointVariants at all, When resolved, Then every entry point stays full', () {
      for (final entryPoint in PaywallEntryPoint.values) {
        final result = resolve(entryPoint: entryPoint);

        expect(result.variant, PaywallProductVariant.full);
        expect(result.productIds, ['google-default-1', 'google-default-2']);
      }
    });

    test('Given an active sale event and a compact entry point, When resolved, Then the sheet keeps its own offer', () {
      // Sale events restyle the FULL paywall only (spec owner's ruling in
      // 9ad35881): the compact sheet carries its own discount and its own
      // fixed 24h clock, so a campaign must not reach in and change it. These
      // two cases asserted the opposite until now — they predate that ruling
      // and had been failing ever since.
      final result = resolve(
        config: _compactConfig(onSaleEvent: true),
        nowUtc: DateTime.utc(2026, 6, 25),
        entryPoint: PaywallEntryPoint.inLesson,
      );

      expect(result.strategyType, ResolvedPaywallStrategyType.defaultUser);
      expect(result.variant, PaywallProductVariant.compact);
      expect(result.productIds, ['google-default-compact']);
    });

    test('Given an active sale event and a compact entry point, When resolved, Then no sale countdown is carried', () {
      final result = resolve(
        config: _compactConfig(onSaleEvent: true),
        nowUtc: DateTime.utc(2026, 6, 25),
        entryPoint: PaywallEntryPoint.inLesson,
      );

      expect(result.hasSaleCountdown, isFalse);
    });

    test('Given the same strategy on two entry points, When resolved, Then the signatures differ', () {
      final config = _compactConfig();

      final compact = resolve(config: config, entryPoint: PaywallEntryPoint.inLesson);
      final full = resolve(config: config, entryPoint: PaywallEntryPoint.profile);

      // If these matched, IapCubit.loadIapProducts would reuse the first
      // entry point's store products for the second.
      expect(compact.signature, isNot(full.signature));
    });

    group('falls back to the full list rather than blanking the paywall', () {
      test('Given an empty compact list, When a compact entry point resolves, Then uses the full list', () {
        final result = resolve(
          config: _compactConfig(defaultUserCompact: const []),
          entryPoint: PaywallEntryPoint.inLesson,
        );

        expect(result.isValid, isTrue);
        expect(result.variant, PaywallProductVariant.full);
        expect(result.productIds, ['google-default-1', 'google-default-2']);
      });

      test('Given a compact list with a blank id for this platform, When resolved, Then uses the full list', () {
        final result = resolve(
          config: _compactConfig(
            defaultUserCompact: const [
              PaywallProductReferenceEntity(appleProductId: 'apple-only-compact'),
            ],
          ),
          entryPoint: PaywallEntryPoint.inLesson,
        );

        expect(result.isValid, isTrue);
        expect(result.variant, PaywallProductVariant.full);
        expect(result.productIds, ['google-default-1', 'google-default-2']);
      });

      test('Given a compact list with duplicate ids, When resolved, Then uses the full list', () {
        final result = resolve(
          config: _compactConfig(
            defaultUserCompact: const [
              PaywallProductReferenceEntity(googleProductId: 'google-dup'),
              PaywallProductReferenceEntity(googleProductId: 'google-dup'),
            ],
          ),
          entryPoint: PaywallEntryPoint.inLesson,
        );

        expect(result.isValid, isTrue);
        expect(result.variant, PaywallProductVariant.full);
        expect(result.productIds, ['google-default-1', 'google-default-2']);
      });
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

/// `entryPointVariants` marking in-lesson as compact, plus a one-SKU reduced
/// list on every strategy — the shipped default of the entry-point-variants
/// feature.
PaywallConfigEntity _compactConfig({
  List<PaywallProductReferenceEntity>? defaultUserCompact,
  bool onSaleEvent = false,
}) {
  final base = onSaleEvent ? _eventConfig() : _config;
  final strategy = base.saleStrategy!;
  return base.copyWith(
    entryPointVariants: const {
      'inLesson': PaywallProductVariant.compact,
      'profile': PaywallProductVariant.full,
    },
    saleStrategy: strategy.copyWith(
      defaultUser: strategy.defaultUser.copyWith(
        compactProducts: defaultUserCompact ??
            const [
              PaywallProductReferenceEntity(appleProductId: 'apple-default-compact', googleProductId: 'google-default-compact'),
            ],
      ),
      saleEvent: strategy.saleEvent?.copyWith(
        compactProducts: const [
          PaywallProductReferenceEntity(appleProductId: 'apple-event-compact', googleProductId: 'google-event-compact'),
        ],
      ),
    ),
  );
}

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
        appliesTo: const [PaywallAudienceSegment.defaultUser],
        content: _content,
        products: const [
          PaywallProductReferenceEntity(appleProductId: 'apple-event', googleProductId: 'google-event'),
        ],
      ),
    ),
  );
}

