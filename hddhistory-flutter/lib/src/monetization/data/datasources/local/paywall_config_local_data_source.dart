part of '../../../monetization.dart';

/// Local cache for the last successful paywall config API response.
///
/// This is the second link in the resolution chain (API -> this cache ->
/// Remote Config -> bundled defaults): it lets a cold start with no network
/// render the last-known-good, admin-authored content instead of falling all
/// the way back to the coarser Remote Config payload. See
/// [MonetizationRepository.getPaywallConfig] and
/// [IapCubit.resolvedPaywallConfig].
abstract class PaywallConfigLocalDataSource {
  /// Raw decoded JSON body of the last successful fetch, or null if there has
  /// never been one (e.g. brand-new install that has never had connectivity).
  Future<Map<String, dynamic>?> getCachedConfig();

  Future<void> cacheConfig(Map<String, dynamic> json);
}

@LazySingleton(as: PaywallConfigLocalDataSource)
class PaywallConfigLocalDataSourceImpl implements PaywallConfigLocalDataSource {
  static const String _cacheKey = 'paywall_config_cache';

  final ILocalStoreService _localStoreService;

  PaywallConfigLocalDataSourceImpl(this._localStoreService);

  @override
  Future<Map<String, dynamic>?> getCachedConfig() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheConfig(Map<String, dynamic> json) async {
    try {
      await _localStoreService.setMap(key: _cacheKey, value: json);
    } catch (_) {
      // Best-effort cache — a failure here must never block the paywall.
    }
  }
}
