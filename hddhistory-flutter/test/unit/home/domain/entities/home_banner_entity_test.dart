import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

/// The Home promo carousel's client-side rules. Targeting is NOT here on purpose
/// — the server filters slides per viewer — so what is left to get right is the
/// version skew in both directions and never rendering an empty card.
/// See `hddhistory-api/plans/260811-home-banner-carousel/README.md`.
void main() {
  group('HomeBannerEntity.effectiveSlides', () {
    test('renders the slides the server sent, in order', () {
      const banner = HomeBannerEntity(
        enabled: true,
        visible: true,
        slides: [
          HomeBannerSlideEntity(imageUrl: 'a.png', linkUrl: 'a'),
          HomeBannerSlideEntity(imageUrl: 'b.png', linkUrl: 'b'),
        ],
      );

      expect(banner.effectiveSlides.map((s) => s.imageUrl), ['a.png', 'b.png']);
      expect(banner.isVisible, isTrue);
    });

    /// A build of this app against an API that predates the carousel: `slides` is
    /// empty but the single banner is there, and the slot must still show it
    /// rather than collapse.
    test('falls back to the single banner when no slides are sent', () {
      const banner = HomeBannerEntity(
        enabled: true,
        visible: true,
        imageUrl: 'legacy.png',
        linkUrl: 'legacy',
      );

      expect(banner.effectiveSlides, hasLength(1));
      expect(banner.effectiveSlides.single.imageUrl, 'legacy.png');
      expect(banner.effectiveSlides.single.linkUrl, 'legacy');
      expect(banner.isVisible, isTrue);
    });

    test('prefers slides over the legacy mirror when both are present', () {
      // The server mirrors the first visible slide into imageUrl for old apps;
      // a new app must not render that mirror as an extra slide.
      const banner = HomeBannerEntity(
        enabled: true,
        visible: true,
        imageUrl: 'a.png',
        slides: [
          HomeBannerSlideEntity(imageUrl: 'a.png'),
          HomeBannerSlideEntity(imageUrl: 'b.png'),
        ],
      );

      expect(banner.effectiveSlides, hasLength(2));
    });

    test('collapses the slot when there is nothing to show', () {
      const off = HomeBannerEntity(enabled: false, visible: false, imageUrl: 'a.png');
      const empty = HomeBannerEntity(enabled: true, visible: true);
      const imagelessSlide = HomeBannerEntity(
        enabled: true,
        visible: true,
        slides: [HomeBannerSlideEntity(linkUrl: 'no-image')],
      );

      expect(off.isVisible, isFalse);
      expect(empty.isVisible, isFalse);
      expect(imagelessSlide.effectiveSlides, isEmpty);
      expect(imagelessSlide.isVisible, isFalse);
    });

    /// `visible` is null on an API older than country targeting; the slot then
    /// falls back to the raw kill switch instead of blanking.
    test('honours the kill switch when the server said nothing', () {
      const banner = HomeBannerEntity(enabled: true, imageUrl: 'a.png');

      expect(banner.isVisible, isTrue);
      expect(const HomeBannerEntity(imageUrl: 'a.png').isVisible, isFalse);
    });
  });

  group('HomeBannerModel', () {
    test('maps the slide list through to the entity', () {
      final model = HomeBannerModel.fromJson({
        'enabled': true,
        'visible': true,
        'imageUrl': 'a.png',
        'linkUrl': 'a',
        'slides': [
          {'imageUrl': 'a.png', 'linkUrl': 'a'},
          {'imageUrl': 'b.png', 'linkUrl': ''},
        ],
      });

      final entity = model.toEntity();

      expect(entity.slides.map((s) => s.imageUrl), ['a.png', 'b.png']);
      expect(entity.effectiveSlides.last.linkUrl, isEmpty);
    });

    test('reads a response with no slides field at all', () {
      final model = HomeBannerModel.fromJson({
        'enabled': true,
        'visible': true,
        'imageUrl': 'legacy.png',
      });

      expect(model.slides, isEmpty);
      expect(model.toEntity().effectiveSlides.single.imageUrl, 'legacy.png');
    });
  });
}
