part of '../services.dart';

enum PurchaseType { consumable, nonConsumable, subscription }

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
      _products.addAll(response.productDetails);
    });
    return _products;
  }

  @override
  Future<bool> purchaseProduct(String productId, PurchaseType type) async {
    final product = _products.firstWhere((element) => element.id == productId);
    final purchaseParam = PurchaseParam(productDetails: product);

    return switch (type) {
      PurchaseType.consumable => await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam),
      PurchaseType.nonConsumable => await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
      PurchaseType.subscription => await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam),
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
      if (!purchaseDetails.pendingCompletePurchase) return;
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
  List<IapProduct> toIapProducts() => map((e) => IapProductExtension.fromProductDetails(e)).toList();
}

extension PurchaseDetailsExtension on PurchaseDetails {
  String get toJsonString =>
      '{"purchaseID": "$purchaseID", \r\n"productID": "$productID", \r\n"transactionDate": "$transactionDate", \r\n"status": "$status", \r\n"verificationData": "${verificationData.toJsonString}"}';
}

extension PurchaseVerificationDataExtension on PurchaseVerificationData {
  String get toJsonString => '{"localVerificationData": "$localVerificationData", \r\n"serverVerificationData": "$serverVerificationData", \r\n"source": "$source"}';
}
