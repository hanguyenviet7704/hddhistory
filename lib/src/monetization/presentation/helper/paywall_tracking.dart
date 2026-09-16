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
  /// [mode] rides alongside as `gift_mode`, and only for the app-open trigger.
  ///
  /// The sheet's `gift_trigger` has ONE value for app-open (`new_user_offer`)
  /// while the popup has two frequency modes behind it — once a day for a week,
  /// or every open. Collapsing them into the sheet's value and stopping there
  /// would leave one funnel that cannot tell a better offer from a louder one,
  /// so the distinction moves to a second param instead of bending the name the
  /// sheet asks for (owner, 2026-09-16). Null everywhere else, and the dispatch
  /// above drops nulls.
  static void giftScrView({required String trigger, String? mode}) {
    track(TrackingKey.paywallGiftScrView, parameters: {'gift_trigger': trigger, 'gift_mode': mode});
  }

  static void giftOpenClick({required String trigger, String? mode}) {
    track(TrackingKey.paywallGiftOpenClick, parameters: {'gift_trigger': trigger, 'gift_mode': mode});
  }

  //* 33%-off compact sheet
  /// [source] is the sheet's paywall `source` vocabulary — the entry point
  /// that opened this sheet, or one of the gift popup's triggers when it came
  /// from there. Resolved by the tracking service so this event agrees with
  /// `paywall_scr_view` and `paywall_success_popup_view` rather than inventing
  /// a second mapping.
  static void offerScrView({required String productId, required String source}) {
    track(TrackingKey.paywallOfferScrView, parameters: {'product_id': productId, 'source': source});
  }

  static void offerClaimClick({required String productId}) {
    track(TrackingKey.paywallOfferClaimClick, parameters: {'product_id': productId});
    // Parity with the full CTA's trackPremiumPurchase, which stamps the bought
    // product on the user for LTV cuts.
    setUserProperties({'product_id': productId});
  }

  static void offerCloseClick() => track(TrackingKey.paywallOfferCloseClick);
}
