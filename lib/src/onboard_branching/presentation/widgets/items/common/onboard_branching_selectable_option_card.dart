part of '../../../../onboard_branching.dart';

class OnboardBranchingSelectableOptionCard extends StatelessWidget {
  const OnboardBranchingSelectableOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingIconUrl = '',
    this.leadingImageUrl = '',
    this.leadingSize = 24,
    this.placeholderColor = const Color(0xFFC7C5FA),
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String leadingIconUrl;
  final String leadingImageUrl;
  final double leadingSize;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF4B44CA) : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x3CE7E7E9),
                    blurRadius: 3,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLeading(),
            12.horizontalSpace,
            AppText(
              label,
              expandFlex: 1,
              maxLines: 5,
              textAlign: TextAlign.start,
              style: AppStyle.text14.copyWith(
                color: isSelected ? const Color(0xFF0D121C) : const Color(0xFF364152),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (leadingImageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CacheNetworkGraphic(
          url: leadingImageUrl,
          width: leadingSize.w,
          height: leadingSize.w,
          fit: BoxFit.cover,
        ),
      );
    }

    if (leadingIconUrl.trim().isNotEmpty) {
      return CacheNetworkGraphic(
        url: leadingIconUrl,
        width: leadingSize.w,
        height: leadingSize.w,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: leadingSize.w,
      height: leadingSize.w,
      color: placeholderColor,
    );
  }
}
