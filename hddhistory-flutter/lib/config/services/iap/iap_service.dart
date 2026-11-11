part of '../services.dart';

enum ProductType {
  @JsonValue('consumable')
  consumable,
  @JsonValue('non_consumable')
  nonConsumable,
  @JsonValue('subscription_auto_renew')
  subscriptionAutoRenew,
  @JsonValue('subscription_non_renew')
  subscriptionNonRenew,
}

@LazySingleton(as: IIapService)
class IAPService implements IIapService {
  late final InAppPurchase _inAppPurchase;

  IAPService() {
    _inAppPurchase = InAppPurchase.instance;
  }

  bool _available = true;
  bool get isAvailable => _available;

  List<ProductDetails> _products = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  Future<void> _safeCall(Function() function) async {
    try {
      await function();
    } on IAPError catch (e) {
      LogDev.fatal('IAPError: ${e.source} - ${e.code} - ${e.message}');
      throw InAppPurchaseException(source: e.source, code: e.code, message: e.message);
    } catch (e) {
      if (kDebugMode) throw InAppPurchaseException(source: 'Unknown', code: '0', message: 'Failed to call function: $e');
    }
  }

  @override
  Future<List<ProductDetails>> getProducts({required Set<String> productIds}) async {
    _products = [];
    await _safeCall(() async {
      _available = await _inAppPurchase.isAvailable();
      if (!_available) return;

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        throw InAppPurchaseException(
          source: response.error?.source ?? 'unknown',
          code: response.error!.code,
          message: response.error!.message,
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        LogDev.warning('IAP products not found: ${response.notFoundIDs.join(', ')}');
      }

      _products.addAll(response.productDetails);
    });
    // DEV only, and only for SKUs the store did not return. A real listing
    // always wins, so this cannot mask one — see [DevMockProducts].
    _products.addAll(DevMockProducts.fillMissing(requestedIds: productIds, resolved: _products));
    return _products;
  }

  @override
  Future<bool> purchaseProduct(String productId, ProductType type) async {
    final product = _products.firstWhere(
      (element) => element.id == productId,
      orElse: () => throw InAppPurchaseException(source: 'client', code: 'product_not_loaded', message: 'Product $productId not loaded'),
    );
    final purchaseParam = PurchaseParam(productDetails: product);

    return switch (type) {
      ProductType.consumable => await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam, autoConsume: true),
      ProductType.nonConsumable => await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
      ProductType.subscriptionAutoRenew => await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
      ProductType.subscriptionNonRenew => await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
    };
  }

  @override
  Future<PurchaseVerificationData?> refreshIOSVerificationData() async {
    try {
      return await _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>().refreshPurchaseVerificationData();
    } catch (e) {
      LogDev.error('Error refreshing verification data: $e');
      return null;
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    _safeCall(() async {
      // Complete/acknowledge only when the SDK reports it pending.
      // if (!purchaseDetails.pendingCompletePurchase) return;
      await _inAppPurchase.completePurchase(purchaseDetails);
    });
  }

  @override
  Future<void> restorePurchases() async {
    await _safeCall(() async {
      await _inAppPurchase.restorePurchases();
    });
  }
}

extension ProductDetailsExtension on ProductDetails {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'currencyCode': currencyCode,
    'description': description,
    'rawPrice': rawPrice,
  };

  static ProductDetails fromJson(Map<String, dynamic> json) => ProductDetails(
    id: json['id'],
    title: json['title'],
    price: json['price'],
    currencyCode: json['currencyCode'],
    description: json['description'],
    rawPrice: double.parse(json['price']),
  );
}

extension ListProductDetailsExtension on List<ProductDetails> {
  List<IapProductModel> toIapProducts() => map((e) => IapProductModelExtension.fromProductDetails(e)).toList();
}

extension PurchaseDetailsExtension on PurchaseDetails {
  String get transactionId => purchaseID?.trim().isNotEmpty == true ? purchaseID! : verificationData.serverVerificationData;

  String get toJsonString =>
      '{"purchaseID": "$purchaseID", \r\n"productID": "$productID", \r\n"transactionDate": "$transactionDate", \r\n"status": "$status", \r\n"verificationData": "${verificationData.toJsonString}"}';
}

extension PurchaseVerificationDataExtension on PurchaseVerificationData {
  String get toJsonString => '{"localVerificationData": "$localVerificationData", \r\n"serverVerificationData": "$serverVerificationData", \r\n"source": "$source"}';
}
