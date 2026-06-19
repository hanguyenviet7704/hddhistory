import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('MonetizationRepository strategy product loading', () {
    test('pages BE catalog, reorders by config, and queries store with exact selected IDs', () async {
      final api = _FakeMonetizationApi([
        _page(1, 2, [_remote('other'), _remote('quarter', bestDeal: true)]),
        _page(2, 2, [_remote('annual', salePercent: 50)]),
      ]);
      final iap = _FakeIapService([
        _store('annual', price: r'$50.00', rawPrice: 50),
        _store('quarter', price: r'$20.00', rawPrice: 20),
      ]);
      final repository = MonetizationRepository(api, iap, _FakeUserSubscriptionLocalDataSource(), _FakeMonetizationLocalDataSource());

      final result = await repository
          .getProducts(
            const GetPackagesParams(
              platform: PaymentPlatform.google,
              selectedProductIds: ['annual', 'quarter'],
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      final products = result.getRight().toNullable()!;
      expect(api.requestedPages, [1, 2]);
      expect(iap.queriedIds.single, {'annual', 'quarter'});
      expect(products.map((product) => product.productId), ['annual', 'quarter']);
      expect(products.first.id, 'row-annual');
      expect(products.first.salePercent, 50);
      expect(products.last.bestDeal, isTrue);
    });

    test('fails whole strategy when any configured BE or store product is missing', () async {
      final missingBe = MonetizationRepository(
        _FakeMonetizationApi([
          _page(1, 1, [_remote('annual')]),
        ]),
        _FakeIapService([_store('annual')]),
        _FakeUserSubscriptionLocalDataSource(),
        _FakeMonetizationLocalDataSource(),
      );
      final missingStore = MonetizationRepository(
        _FakeMonetizationApi([
          _page(1, 1, [_remote('annual'), _remote('quarter')]),
        ]),
        _FakeIapService([_store('annual')]),
        _FakeUserSubscriptionLocalDataSource(),
        _FakeMonetizationLocalDataSource(),
      );

      for (final repository in [missingBe, missingStore]) {
        final result = await repository
            .getProducts(
              const GetPackagesParams(
                platform: PaymentPlatform.google,
                selectedProductIds: ['annual', 'quarter'],
              ),
            )
            .run();

        expect(result.isLeft(), isTrue);
      }
    });
  });
}

BaseResponse<BasePageBreak<IapProductModel>> _page(int currentPage, int totalPages, List<IapProductModel> items) {
  return BaseResponse(
    status: true,
    code: '200',
    message: 'ok',
    data: BasePageBreak(
      currentPage: currentPage,
      totalPages: totalPages,
      itemsPerPage: 10,
      items: items,
    ),
  );
}

IapProductModel _remote(String productId, {bool bestDeal = false, double salePercent = 0}) {
  return IapProductModel(
    id: 'row-$productId',
    productId: productId,
    platform: PaymentPlatform.google,
    type: ProductType.subscriptionAutoRenew,
    salePercent: salePercent,
    bestDeal: bestDeal,
  );
}

ProductDetails _store(String id, {String price = r'$10.00', double rawPrice = 10}) {
  return ProductDetails(
    id: id,
    title: 'Store $id',
    description: 'Store description $id',
    price: price,
    rawPrice: rawPrice,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );
}

class _FakeMonetizationApi implements MonetizationApi {
  final List<BaseResponse<BasePageBreak<IapProductModel>>> pages;
  final List<int> requestedPages = [];

  _FakeMonetizationApi(this.pages);

  @override
  Future<BaseResponse<BasePageBreak<IapProductModel>>> getPackages(PageBreakRequest params) async {
    requestedPages.add(params.page);
    return pages[params.page - 1];
  }

  @override
  Future<BaseResponse<IapVerifyModel>> verify(Map<String, dynamic> params) async => const BaseResponse(data: IapVerifyModel());
}

class _FakeIapService implements IIapService {
  final List<ProductDetails> products;
  final List<Set<String>> queriedIds = [];

  _FakeIapService(this.products);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {}

  @override
  Future<List<ProductDetails>> getProducts({required Set<String> productIds}) async {
    queriedIds.add(productIds);
    return products.where((product) => productIds.contains(product.id)).toList();
  }

  @override
  Future<bool> purchaseProduct(String productId, ProductType type) async => true;

  @override
  Future<PurchaseVerificationData?> refreshIOSVerificationData() async => null;

  @override
  Future<void> restorePurchases() async {}
}

class _FakeUserSubscriptionLocalDataSource implements UserSubscriptionLocalDataSource {
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

class _FakeMonetizationLocalDataSource implements MonetizationLocalDataSource {
  int impressionCount = 0;

  @override
  Future<void> cacheIapProduct(IapProductModel model) async {}

  @override
  Future<void> cacheIapProducts(List<IapProductModel> models) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<void> deleteCachedIapProduct(String id) async {}

  @override
  Future<IapProductModel?> getCachedIapProduct(String id) async => null;

  @override
  Future<List<IapProductModel>> getCachedIapProducts() async => [];

  @override
  Future<int> getNewUserPaywallImpressionCount() async => impressionCount;

  @override
  Future<void> setNewUserPaywallImpressionCount(int count) async => impressionCount = count;
}
