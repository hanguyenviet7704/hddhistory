part of '../../onboard.dart';

class ForceUpdateContent extends StatelessWidget {
  final VoidCallback? onUpdatePressed;

  const ForceUpdateContent({
    super.key,
    this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIllustrationSection(),
          _buildContentSection(context),
        ],
      ),
    );
  }

  Widget _buildIllustrationSection() {
    return Container(
      width: double.infinity,
      height: 286.h,
      decoration: BoxDecoration(
        color: const Color(0xFFD9F4FD),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: DCachedImage(
        url: AppAsset.images.common.mainIcon.path,
        height: 286.h,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: IntrinsicWidth(
        child: Column(
          children: [
            _buildTextContent(context),
            SizedBox(height: 24.h),
            _buildUpdateButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      children: [
        AppText(
          'context.text.updateNewVersionAvailable',
          style: AppStyle.textBold32.copyWith(
            color: const Color(0xFF0D121C),
            height: 40.h / 32.sp,
          ),
          textAlign: TextAlign.center,
        ),
        8.verticalSpace,
        AppText(
          'context.text.updateUpdateNowToEnjoy',
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF364152),
            height: 32.h / 20.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    return AppButton.primary(
      onPressed: onUpdatePressed,
      child: AppText(
        'context.text.updateUpdateNow',
        style: AppStyle.textBold20.copyWith(
          color: Colors.white,
          height: 28.h / 20.sp,
        ),
      ),
    );
  }
}
