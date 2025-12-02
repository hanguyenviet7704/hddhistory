part of '../../monetization.dart';

Future<void> showPaywallPlanBottomSheet(
  BuildContext context, {
  required List<IapProductEntity> products,
  required String selectedProductId,
  required ValueChanged<String> onSelect,
  required VoidCallback onPurchase,
}) async {
  if (products.isEmpty) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return PaywallPlanSheet(
        products: products,
        selectedProductId: selectedProductId,
        onSelect: onSelect,
        onPurchase: onPurchase,
      );
    },
  );
}

class PaywallPlanSheet extends StatefulWidget {
  const PaywallPlanSheet({
    super.key,
    required this.products,
    required this.selectedProductId,
    required this.onSelect,
    required this.onPurchase,
  });

  final List<IapProductEntity> products;
  final String selectedProductId;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;

  @override
  State<PaywallPlanSheet> createState() => _PaywallPlanSheetState();
}

class _PaywallPlanSheetState extends State<PaywallPlanSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedProductId.isNotEmpty ? widget.selectedProductId : widget.products.first.id;
  }

  IapProductEntity get _selectedProduct => widget.products.firstWhere((element) => element.id == _selectedId, orElse: () => widget.products.first);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.h),
        decoration: BoxDecoration(
          color: AppColorLight.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            12.verticalSpace,
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppCustomColor.borderSecondary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            12.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  AppText(
                    context.text.monetization.seeAllPlans,
                    style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, size: 22.sp, color: AppCustomColor.textSecondary),
                  ),
                ],
              ),
            ),
            4.verticalSpace,
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return PaywallPlanCard(
                    product: product,
                    isSelected: product.id == _selectedId,
                    isMostPopular: index == 0,
                    isCompact: true,
                    onTap: () {
                      setState(() => _selectedId = product.id);
                      widget.onSelect(product.id);
                    },
                  );
                },
                separatorBuilder: (_, __) => 10.verticalSpace,
                itemCount: widget.products.length,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: AppButton.primary(
                fullWidthBtn: true,
                onPressed: widget.onPurchase,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: AppText(
                  '${context.text.monetization.payNowCta} • ${_selectedProduct.price}',
                  style: AppStyle.textBold18.copyWith(color: AppCustomColor.textWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
