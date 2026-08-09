import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// Covers the API -> local cache half of the paywall config resolution
/// chain (API -> cache -> Remote Config -> bundled defaults). The Remote
/// Config / bundled-default half is covered by IapCubit's
/// `resolvedPaywallConfig`, tested in
/// iap_cubit_paywall_config_fallback_test.dart.
void main() {
  group('MonetizationRepository.getPaywallConfig', () {
    test('Given a healthy API, When fetched, Then it parses via fromRawConfig and writes through to the cache', () async {
      final api = _FakePaywallConfigApi(response: _rawConfig(lessonLock: 7));
      final cache = _FakePaywallConfigLocalDataSource();
      final repository = _buildRepository(api: api, cache: cache);

      final result = await repository.getPaywallConfig().run();

      expect(result.isRight(), isTrue);
      final config = result.getRight().toNullable()!;
      expect(config.lessonLock, 7);
      expect(config.schemaVersion, 2);
      expect(cache.cacheConfigCalls, 1);
      expect(cache.lastCached?['lessonLock'], 7);
    });

    test('Given the API fails, When a cached response exists, Then it silently falls back to the cache', () async {
      final api = _FakePaywallConfigApi(shouldThrow: true);
      final cache = _FakePaywallConfigLocalDataSource(seed: _rawConfig(lessonLock: 3));
      final repository = _buildRepository(api: api, cache: cache);

      final result = await repository.getPaywallConfig().run();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.lessonLock, 3);
      // A background refresh failure must never surface a user-visible error.
      expect(cache.cacheConfigCalls, 0);
    });

    test('Given the API fails and there is no cache, When fetched, Then it resolves Left so the caller can fall to Remote Config', () async {
      final api = _FakePaywallConfigApi(shouldThrow: true);
      final cache = _FakePaywallConfigLocalDataSource();
      final repository = _buildRepository(api: api, cache: cache);

      final result = await repository.getPaywallConfig().run();

      expect(result.isLeft(), isTrue);
    });
  });
}

Map<String, dynamic> _rawConfig({required int lessonLock}) => {
  'schemaVersion': 2,
  'enableLessonLock': true,
  'lessonLock': lessonLock,
  'autoOpen': {'enabled': false, 'sessionRolloutPercent': 0},
};

MonetizationRepository _buildRepository({
  required PaywallConfigApi api,
  required PaywallConfigLocalDataSource cache,
}) {
  return MonetizationRepository(
    _NoopMonetizationApi(),
    _NoopIapService(),
    _NoopUserSubscriptionLocalDataSource(),
    api,
    cache,
  );
}

class _FakePaywallConfigApi implements PaywallConfigApi {
  _FakePaywallConfigApi({this.response, this.shouldThrow = false});

  final Map<String, dynamic>? response;
  final bool shouldThrow;

  @override
  Future<BaseResponse<dynamic>> getPaywallConfig() async {
    if (shouldThrow) throw Exception('network down');
    return BaseResponse(status: true, code: '200', data: response);
  }
}

class _FakePaywallConfigLocalDataSource implements PaywallConfigLocalDataSource {
  _FakePaywallConfigLocalDataSource({Map<String, dynamic>? seed}) : _cached = seed;

  Map<String, dynamic>? _cached;
  Map<String, dynamic>? lastCached;
  int cacheConfigCalls = 0;

  @override
  Future<Map<String, dynamic>?> getCachedConfig() async => _cached;

  @override
  Future<void> cacheConfig(Map<String, dynamic> json) async {
    cacheConfigCalls++;
    lastCached = json;
    _cached = json;
  }
}

class _NoopMonetizationApi implements MonetizationApi {
  @override
  Future<BaseResponse<BasePageBreak<IapProductModel>>> getPackages(PageBreakRequest params) async {
    throw UnimplementedError();
  }

  @override
  Future<BaseResponse<IapVerifyModel>> verify(Map<String, dynamic> params) async => throw UnimplementedError();

  @override
  Future<BaseResponse<VoucherValidationModel>> validateVoucher(Map<String, dynamic> params) async => throw UnimplementedError();
}

class _NoopIapService implements IIapService {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {}

  @override
  Future<List<ProductDetails>> getProducts({required Set<String> productIds}) async => [];

  @override
  Future<bool> purchaseProduct(String productId, ProductType type) async => true;

  @override
  Future<PurchaseVerificationData?> refreshIOSVerificationData() async => null;

  @override
  Future<void> restorePurchases() async {}
}

class _NoopUserSubscriptionLocalDataSource implements UserSubscriptionLocalDataSource {
  @override
  Future<List<String>> getProcessedTransactionIds() async => [];

  @override
  Future<void> cacheProcessedTransactionIds(List<String> ids) async {}

  @override
  Future<IapSubscriptionModel?> getCachedUserSubscription(String userId) async => null;

  @override
  Future<void> cacheUserSubscription(String userId, IapSubscriptionModel model) async {}

  @override
  Future<void> clearCache() async {}
}
