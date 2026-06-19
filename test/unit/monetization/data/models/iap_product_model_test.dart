import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('IapProductModelListExtension.mapStoreData', () {
    test('Given BE and store return different order, When merged, Then BE/config order and BE flags are preserved', () {
      const remote = [
        IapProductModel(id: 'row-annual', productId: 'annual', rawPrice: 1, salePercent: 50, bestDeal: true),
        IapProductModel(id: 'row-quarter', productId: 'quarter', rawPrice: 1, salePercent: 20),
      ];
      const store = [
        IapProductModel(productId: 'quarter', title: 'Quarter', price: r'$20.00', rawPrice: 20, currencySymbol: r'$'),
        IapProductModel(productId: 'annual', title: 'Annual', price: r'$50.00', rawPrice: 50, currencySymbol: r'$'),
      ];

      final result = remote.mapStoreData(store);

      expect(result.map((product) => product.id), ['row-annual', 'row-quarter']);
      expect(result.map((product) => product.productId), ['annual', 'quarter']);
      expect(result.first.bestDeal, isTrue);
      expect(result.first.salePercent, 50);
      expect(result.first.price, r'$50.00');
      expect(result.last.price, r'$20.00');
    });
  });
}
