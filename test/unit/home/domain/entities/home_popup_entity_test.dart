import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

/// The popup's client-side rules. Targeting and the "already tapped" check live on
/// the server, so what is left here is the guard against raising a modal we cannot
/// retire — which is where this deliberately differs from the banner.
/// See `hddhistory-api/plans/260811-home-popup/README.md`.
void main() {
  group('HomePopupEntity.isVisible', () {
    const ready = HomePopupEntity(
      enabled: true,
      visible: true,
      imageUrl: 'promo.png',
      linkUrl: 'https://meup.training/r/promo',
      campaignKey: '3f2a1c9d8e7b6a54',
    );

    test('shows when the server said so and there is something to show', () {
      expect(ready.isVisible, isTrue);
    });

    test('hides when the server said hide', () {
      expect(ready.copyWith(visible: false).isVisible, isFalse);
    });

    /// The banner falls back to `enabled` when `visible` is null (an older API);
    /// this must NOT. A modal that interrupts, on an API with no click endpoint,
    /// could never be retired — it would come back every session forever.
    test('stays hidden when the server said nothing, even with the switch on', () {
      expect(ready.copyWith(visible: null).isVisible, isFalse);
      expect(
        const HomePopupEntity(enabled: true, imageUrl: 'promo.png', campaignKey: 'abc1234567890def').isVisible,
        isFalse,
      );
    });

    test('hides without an image — a blank modal is worse than none', () {
      expect(ready.copyWith(imageUrl: '').isVisible, isFalse);
    });

    /// Without a key the tap could not be recorded, so the popup would return
    /// forever. Refusing to show it is the honest response.
    test('hides without a campaign key', () {
      expect(ready.copyWith(campaignKey: '').isVisible, isFalse);
    });

    test('shows even with no link — then it is just an announcement', () {
      expect(ready.copyWith(linkUrl: '').isVisible, isTrue);
    });
  });

  group('HomePopupModel', () {
    test('maps the server response through to the entity', () {
      final model = HomePopupModel.fromJson({
        'enabled': true,
        'visible': true,
        'imageUrl': 'promo.png',
        'linkUrl': 'https://meup.training/r/promo',
        'campaignKey': '3f2a1c9d8e7b6a54',
      });

      expect(model.toEntity().isVisible, isTrue);
      expect(model.toEntity().campaignKey, '3f2a1c9d8e7b6a54');
    });

    test('reads a response from an API that has no popup at all', () {
      final model = HomePopupModel.fromJson(<String, dynamic>{});

      expect(model.visible, isNull);
      expect(model.toEntity().isVisible, isFalse);
    });

    test('reads the click reply', () {
      expect(HomePopupClickResultModel.fromJson({'recorded': true}).recorded, isTrue);
      expect(HomePopupClickResultModel.fromJson(<String, dynamic>{}).recorded, isFalse);
    });
  });
}
