part of '../services.dart';

abstract interface class IIapService {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<List<ProductDetails>> getProducts({required Set<String> productIds});
  Future<bool> purchaseProduct(String productId, PurchaseType type);
  Future<PurchaseVerificationData?> refreshIOSVerificationData();
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchaseDetails);
}
