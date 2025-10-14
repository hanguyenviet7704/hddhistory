part of '../utils.dart';

void showDYesNoDialog({
  BuildContext? context,
  String title = '',
  String message = '',
  List<Widget>? body,
  String yesText = '',
  String noText = '',
  EdgeInsets? insetPadding,
  required Function() onYes,
  void Function()? onNo,
}) {

  assert(message.isNotEmpty || body != null, 'message or body must be provided');
  context ??= AppConfig.instance.context!;

  if (title.isEmpty) {
    title = 'notification';
  }
  if (yesText.isEmpty) {
    yesText = context.text.yes;
  }
  if (noText.isEmpty) {
    noText = context.text.cancel;
  }

  showStandardDDiaLog(
    context,
    title: title,
    width: 620.w,
    actionsPadding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
    enableBackButton: false,
    insetPadding: insetPadding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
    bodyPadding: EdgeInsets.symmetric(horizontal: 32.w),
    body:
        body ??
        [
          AppText(message, style: AppStyle.text20.copyWith(fontWeight: FontWeight.w500), maxLines: 5),
        ],
    actions: [
      DButton(
        customChild: AppText(yesText, style: AppStyle.textBold20.copyWith(color: AppCustomColor.grey69)),
        backgroundColor: AppCustomColor.greyEE,
        style: AppStyle.text20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        size: Size(262.w, 60.h),
        onPressed: onYes,
        padding: EdgeInsets.zero,
      ),
      32.horizontalSpace,
      DButton(
        customChild: AppText(noText, style: AppStyle.textBold20.copyWith(color: AppCustomColor.successRedText)),
        backgroundColor: AppCustomColor.successRedBackground.op(0.36),
        style: AppStyle.text20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        size: Size(262.w, 60.h),
        onPressed: onNo ?? DNavigator.back,
        padding: EdgeInsets.zero,
      ),
    ],
  );
}
