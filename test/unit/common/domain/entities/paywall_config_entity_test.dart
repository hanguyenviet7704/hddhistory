import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('PaywallConfigEntity.fromRawConfig', () {
    test('Given the approved schema, When parsed, Then pivots locale-major content and preserves product order', () {
      final config = PaywallConfigEntity.fromRawConfig(_approvedConfig);

      expect(config.schemaVersion, 2);
      expect(config.enableLessonLock, isFalse);
      expect(config.lessonLock, 5);
      expect(config.autoOpen.enabled, isTrue);
      expect(config.autoOpen.sessionRolloutPercent, 50);
      expect(config.saleStrategy, isNotNull);

      final defaultUser = config.saleStrategy!.defaultUser;
      expect(defaultUser.content.subheading.en, 'Don’t just scroll.');
      expect(defaultUser.content.heading.vi, 'Học một điều mới mỗi ngày');
      expect(defaultUser.content.benefits, hasLength(3));
      expect(defaultUser.content.benefits.first.title.vi, 'Bài học ngắn gọn phù hợp với lịch của bạn');
      expect(
        defaultUser.products.map((product) => product.appleProductId),
        ['meup_premium_annual', 'meup_premium_quarterly'],
      );

      final newUser = config.saleStrategy!.newUser;
      expect(newUser.impressionRules.map((rule) => rule.fromImpression), [1, 2, 3]);
      expect(newUser.content.benefits.first.icon.en, 'https://cdn.example.com/paywall/open-book.png');
      expect(config.saleStrategy!.saleEvent?.campaignId, 'summer_sale_2026');
    });

    test('Given legacy lesson-lock JSON, When parsed, Then keeps old values and disables auto-open', () {
      final config = PaywallConfigEntity.fromRawConfig('{"enableLessonLock":true,"lessonLock":7}');

      expect(config.enableLessonLock, isTrue);
      expect(config.lessonLock, 7);
      expect(config.autoOpen.enabled, isFalse);
      expect(config.saleStrategy, isNull);
    });

    test('Given malformed or non-object JSON, When parsed, Then returns the safe default without throwing', () {
      for (final raw in ['', '{bad', '[]', 'null']) {
        expect(() => PaywallConfigEntity.fromRawConfig(raw), returnsNormally);
        final config = PaywallConfigEntity.fromRawConfig(raw);
        expect(config, const PaywallConfigEntity());
        expect(config.autoOpen.enabled, isFalse);
      }
    });

    test('Given unequal locale benefit counts, When parsed, Then index-pivots to the maximum length with empty cells', () {
      final raw = jsonEncode({
        'schemaVersion': 2,
        'saleStrategy': {
          'defaultUser': {
            'content': {
              'en': {
                'heading': 'English',
                'benefits': [
                  {'icon': 'en-1', 'title': 'English one'},
                ],
              },
              'vi': {
                'heading': 'Vietnamese',
                'benefits': [
                  {'icon': 'vi-1', 'title': 'Vietnamese one'},
                  {'icon': 'vi-2', 'title': 'Vietnamese two'},
                ],
              },
            },
            'products': [
              {'appleProductId': 'apple', 'googleProductId': 'google'},
            ],
          },
          'newUser': {'enabled': false, 'windowDays': 7, 'content': {}, 'impressionRules': []},
        },
      });

      final benefits = PaywallConfigEntity.fromRawConfig(raw).saleStrategy!.defaultUser.content.benefits;

      expect(benefits, hasLength(2));
      expect(benefits[1].title.en, isEmpty);
      expect(benefits[1].title.vi, 'Vietnamese two');
      expect(benefits[1].icon.en, isEmpty);
      expect(benefits[1].icon.vi, 'vi-2');
    });

    test('Given invalid rollout percentage, When parsed, Then auto-open fails closed while strategies remain available', () {
      final map = jsonDecode(_approvedConfig) as Map<String, dynamic>;
      (map['autoOpen'] as Map<String, dynamic>)['sessionRolloutPercent'] = 101;

      final config = PaywallConfigEntity.fromRawConfig(jsonEncode(map));

      expect(config.autoOpen.enabled, isFalse);
      expect(config.saleStrategy, isNotNull);
    });

    test('Given fractional integer fields, When parsed, Then they are rejected instead of truncated', () {
      final map = jsonDecode(_approvedConfig) as Map<String, dynamic>;
      (map['autoOpen'] as Map<String, dynamic>)['sessionRolloutPercent'] = 99.9;
      final newUser = (map['saleStrategy'] as Map<String, dynamic>)['newUser'] as Map<String, dynamic>;
      newUser['windowDays'] = 7.9;
      (newUser['impressionRules'] as List).first['fromImpression'] = 1.5;

      final config = PaywallConfigEntity.fromRawConfig(jsonEncode(map));

      expect(config.autoOpen.enabled, isFalse);
      expect(config.autoOpen.sessionRolloutPercent, 0);
      expect(config.saleStrategy!.newUser.windowDays, 0);
      expect(config.saleStrategy!.newUser.impressionRules.first.fromImpression, 0);
    });

    test('Given an invalid optional event window, When parsed, Then skips the event and retains base strategies', () {
      final map = jsonDecode(_approvedConfig) as Map<String, dynamic>;
      final event = ((map['saleStrategy'] as Map<String, dynamic>)['saleEvent'] as Map<String, dynamic>);
      event['startAtUtc'] = '2026-07-01T00:00:00Z';
      event['endAtUtc'] = '2026-06-01T00:00:00Z';

      final config = PaywallConfigEntity.fromRawConfig(jsonEncode(map));

      expect(config.saleStrategy, isNotNull);
      expect(config.saleStrategy!.saleEvent, isNull);
      expect(config.saleStrategy!.defaultUser.products, isNotEmpty);
    });

    test('Given malformed product entries, When parsed, Then selected strategy fails closed instead of dropping entries', () {
      final map = jsonDecode(_approvedConfig) as Map<String, dynamic>;
      final defaultUser = (map['saleStrategy'] as Map<String, dynamic>)['defaultUser'] as Map<String, dynamic>;
      defaultUser['products'] = [
        {'appleProductId': 'valid-apple', 'googleProductId': 'valid-google'},
        'bad-entry',
      ];

      final config = PaywallConfigEntity.fromRawConfig(jsonEncode(map));
      const resolver = ResolvePaywallStrategyUsecase();
      final resolved = resolver(
        ResolvePaywallStrategyParams(
          config: config,
          platform: PaymentPlatform.google,
          nowUtc: DateTime.utc(2026, 7, 10),
        ),
      );

      expect(config.saleStrategy!.defaultUser.products, hasLength(2));
      expect(resolved.isValid, isFalse);
    });

    test('Given normalized entity JSON, When round-tripped, Then retains multilingual content', () {
      final parsed = PaywallConfigEntity.fromRawConfig(_approvedConfig);
      final roundTripped = PaywallConfigEntity.fromJson(parsed.toJson());

      expect(roundTripped, parsed);
    });

    test('Given no entryPointVariants key, When parsed, Then every entry point reads as full', () {
      final config = PaywallConfigEntity.fromRawConfig(_approvedConfig);

      expect(config.entryPointVariants, isEmpty);
      expect(config.variantForEntryPoint('inLesson'), PaywallProductVariant.full);
      expect(config.variantForEntryPoint('profile'), PaywallProductVariant.full);
    });

    test('Given entryPointVariants, When parsed, Then known values map and unknown ones fall back to full', () {
      final config = PaywallConfigEntity.fromRawConfig(r'''
{
  "schemaVersion": 2,
  "enableLessonLock": false,
  "lessonLock": 5,
  "autoOpen": {"enabled": false, "sessionRolloutPercent": 0},
  "entryPointVariants": {
    "inLesson": "compact",
    "profile": "full",
    "habit": "medium",
    "theme": 3
  },
  "saleStrategy": {
    "defaultUser": {
      "content": {"en": {"heading": "Head"}},
      "products": [{"appleProductId": "a1", "googleProductId": "g1"}],
      "compactProducts": [{"appleProductId": "a1m", "googleProductId": "g1m"}]
    },
    "newUser": {"enabled": false, "windowDays": 0, "impressionRules": []},
    "saleEvent": {"enabled": false}
  }
}
''');

      expect(config.variantForEntryPoint('inLesson'), PaywallProductVariant.compact);
      expect(config.variantForEntryPoint('profile'), PaywallProductVariant.full);
      // Unparseable values are dropped rather than guessed at, so the getter's
      // safe default applies.
      expect(config.variantForEntryPoint('habit'), PaywallProductVariant.full);
      expect(config.variantForEntryPoint('theme'), PaywallProductVariant.full);
      expect(config.variantForEntryPoint('autoOpen'), PaywallProductVariant.full);
      expect(config.saleStrategy!.defaultUser.compactProducts, hasLength(1));
      expect(config.saleStrategy!.defaultUser.compactProducts.first.googleProductId, 'g1m');
    });

    test('Given no compactProducts anywhere, When parsed, Then each strategy has an empty reduced list', () {
      final config = PaywallConfigEntity.fromRawConfig(_approvedConfig);
      final strategy = config.saleStrategy!;

      expect(strategy.defaultUser.compactProducts, isEmpty);
      expect(strategy.newUser.impressionRules.every((rule) => rule.compactProducts.isEmpty), isTrue);
    });
  });
}

const _approvedConfig = r'''
{
  "schemaVersion": 2,
  "enableLessonLock": false,
  "lessonLock": 5,
  "autoOpen": {"enabled": true, "sessionRolloutPercent": 50},
  "saleStrategy": {
    "defaultUser": {
      "content": {
        "en": {
          "subheading": "Don’t just scroll.",
          "heading": "Learn something every day",
          "benefits": [
            {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Bite-sized lessons that fit your schedule"},
            {"icon": "https://cdn.example.com/paywall/statistic.png", "title": "Practice real situations and build useful skills"},
            {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Track your progress and grow step by step"}
          ]
        },
        "vi": {
          "subheading": "Đừng chỉ lướt mãi.",
          "heading": "Học một điều mới mỗi ngày",
          "benefits": [
            {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Bài học ngắn gọn phù hợp với lịch của bạn"},
            {"icon": "https://cdn.example.com/paywall/statistic.png", "title": "Luyện tập tình huống thực tế và xây dựng kỹ năng hữu ích"},
            {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Theo dõi tiến độ và tiến bộ từng bước"}
          ]
        },
        "zh": {}, "ja": {}, "ko": {}
      },
      "products": [
        {"appleProductId": "meup_premium_annual", "googleProductId": "meup_premium_annual"},
        {"appleProductId": "meup_premium_quarterly", "googleProductId": "meup_premium_quarterly"}
      ]
    },
    "newUser": {
      "enabled": true,
      "windowDays": 7,
      "content": {
        "en": {"benefits": [
          {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Bite-sized lessons that fit your schedule"},
          {"icon": "https://cdn.example.com/paywall/statistic.png", "title": "Practice real situations and build useful skills"},
          {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Track your progress and grow step by step"}
        ]},
        "vi": {"benefits": [
          {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Bài học ngắn gọn phù hợp với lịch của bạn"},
          {"icon": "https://cdn.example.com/paywall/statistic.png", "title": "Luyện tập tình huống thực tế và xây dựng kỹ năng hữu ích"},
          {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Theo dõi tiến độ và tiến bộ từng bước"}
        ]},
        "zh": {}, "ja": {}, "ko": {}
      },
      "impressionRules": [
        {"fromImpression": 1, "content": {"en": {"subheading": "Don’t just scroll.", "heading": "Learn something every day"}, "vi": {"subheading": "Đừng chỉ lướt mãi.", "heading": "Học một điều mới mỗi ngày"}, "zh": {}, "ja": {}, "ko": {}}, "products": [{"appleProductId": "meup_premium_annual", "googleProductId": "meup_premium_annual"}, {"appleProductId": "meup_premium_quarterly", "googleProductId": "meup_premium_quarterly"}]},
        {"fromImpression": 2, "content": {"en": {"subheading": "Keep your streak going.", "heading": "Premium helps you learn faster"}, "vi": {"subheading": "Giữ nhịp học tiếp tục.", "heading": "Premium giúp bạn học nhanh hơn"}, "zh": {}, "ja": {}, "ko": {}}, "products": [{"appleProductId": "meup_premium_annual_d20", "googleProductId": "meup_premium_annual_d20"}, {"appleProductId": "meup_premium_quarterly_d20", "googleProductId": "meup_premium_quarterly_d20"}]},
        {"fromImpression": 3, "content": {"en": {"subheading": "Last chance for your best offer.", "heading": "Unlock Premium before this deal ends"}, "vi": {"subheading": "Cơ hội tốt nhất cuối cùng.", "heading": "Mở khóa Premium trước khi ưu đãi kết thúc"}, "zh": {}, "ja": {}, "ko": {}}, "products": [{"appleProductId": "meup_premium_annual_d30", "googleProductId": "meup_premium_annual_d30"}, {"appleProductId": "meup_premium_quarterly_d30", "googleProductId": "meup_premium_quarterly_d30"}]}
      ]
    },
    "saleEvent": {
      "enabled": false,
      "campaignId": "summer_sale_2026",
      "startAtUtc": "2026-06-20T00:00:00Z",
      "endAtUtc": "2026-06-30T23:59:59Z",
      "appliesTo": ["newUser", "defaultUser"],
      "content": {
        "en": {"subheading": "Limited time offer.", "heading": "Unlock Premium today", "benefits": [{"icon": "https://cdn.example.com/paywall/lightning.png", "title": "Save more during this campaign"}, {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Get full access to every lesson"}, {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Track your progress and keep growing"}]},
        "vi": {"subheading": "Ưu đãi có hạn.", "heading": "Mở khóa Premium hôm nay", "benefits": [{"icon": "https://cdn.example.com/paywall/lightning.png", "title": "Tiết kiệm hơn trong chiến dịch này"}, {"icon": "https://cdn.example.com/paywall/open-book.png", "title": "Mở toàn bộ bài học"}, {"icon": "https://cdn.example.com/paywall/chart.png", "title": "Theo dõi tiến độ và tiếp tục phát triển"}]},
        "zh": {}, "ja": {}, "ko": {}
      },
      "products": [{"appleProductId": "meup_premium_annual_event50", "googleProductId": "meup_premium_annual_event50"}, {"appleProductId": "meup_premium_quarterly_event50", "googleProductId": "meup_premium_quarterly_event50"}]
    }
  }
}
''';
