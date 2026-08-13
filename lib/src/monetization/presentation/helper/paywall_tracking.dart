part of '../../monetization.dart';

/// Analytics for the tracking sheet's "new" tab (2026-08): the special gift
/// popup and the 33%-off compact sheet.
///
/// Mirrors [HabitTracking]'s safe dispatch shape: fire-and-forget, try/catch +
/// `.catchError` + `unawaited` — a tracking failure can never break the
/// purchase flow it is attached to.
class PaywallTracking {
  const PaywallTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  static void setUserProperties(Map<String, dynamic> properties) {
    final props = <String, dynamic>{...properties}..removeWhere((_, value) => value == null || (value is String && value.trim().isEmpty));
    if (props.isEmpty) return;
    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.setUserProperties(props).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  //* Special gift popup ("A special gift for you!")
  static void giftScrView({required String trigger}) {
    track(TrackingKey.paywallGiftScrView, parameters: {'gift_trigger': trigger});
  }

  static void giftOpenClick({required String trigger}) {
    track(TrackingKey.paywallGiftOpenClick, parameters: {'gift_trigger': trigger});
  }

  //* 33%-off compact sheet
  static void offerScrView({required String productId}) {
    track(TrackingKey.paywallOfferScrView, parameters: {'product_id': productId});
  }

  static void offerClaimClick({required String productId}) {
    track(TrackingKey.paywallOfferClaimClick, parameters: {'product_id': productId});
    // Parity with the full CTA's trackPremiumPurchase, which stamps the bought
    // product on the user for LTV cuts.
    setUserProperties({'product_id': productId});
  }

  static void offerCloseClick() => track(TrackingKey.paywallOfferCloseClick);
}
