part of '../../../course.dart';

class _AdditionalContentRequestTextArea extends StatelessWidget {
  final TextEditingController controller;

  const _AdditionalContentRequestTextArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppCustomColor.borderDefault, width: 2.w),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textPrimary,
          height: 1.75,
        ),
        cursorColor: AppCustomColor.brandPrimary,
        decoration: InputDecoration.collapsed(
          hintText: context.l10n.courseroadmap.additionalContentRequestPopupPlaceholder,
          hintStyle: AppStyle.text14.copyWith(
            color: const Color(0xFF5F6F86),
            height: 1.75,
          ),
        ),
      ),
    );
  }
}

class _AdditionalContentRequestPopupActions extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onLater;
  final VoidCallback onSend;

  const _AdditionalContentRequestPopupActions({
    required this.isSubmitting,
    required this.onLater,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AdditionalContentRequestActionButton(
          width: 100.w,
          label: context.l10n.courseroadmap.additionalContentRequestLaterCta,
          enabled: !isSubmitting,
          onTap: onLater,
        ),
        8.horizontalSpace,
        Expanded(
          child: _AdditionalContentRequestActionButton(
            label: context.l10n.courseroadmap.additionalContentRequestSendCta,
            primary: true,
            enabled: !isSubmitting,
            onTap: onSend,
          ),
        ),
      ],
    );
  }
}

class _AdditionalContentRequestActionButton extends StatelessWidget {
  final String label;
  final bool primary;
  final bool enabled;
  final double? width;
  final VoidCallback onTap;

  const _AdditionalContentRequestActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.primary = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppCustomColor.textWhite : const Color(0xFF5F6F86);
    return SizedBox(
      width: width,
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primary ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(1000.r),
          border: primary ? null : Border.all(color: AppCustomColor.borderDefault, width: 2.w),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(1000.r),
            child: Center(
              child: AppText(
                label,
                textAlign: TextAlign.center,
                style: AppStyle.text16.copyWith(
                  color: foreground.op(enabled ? 1 : 0.5),
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
