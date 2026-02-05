// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../utils.dart';

/// A customizable dialog content widget.
///
/// This widget represents the content structure of a dialog with title, body, and actions.
class DDialogContent extends StatelessWidget {
  /// The title of the dialog.
  final String title;

  /// The body widgets of the dialog.
  final List<Widget>? body;

  /// The action widgets of the dialog.
  final List<Widget>? actions;

  /// Whether to show a close button.
  final bool enableBackButton;

  /// The padding for the title section.
  final EdgeInsetsGeometry? titlePadding;

  /// The padding for the body section.
  final EdgeInsetsGeometry? bodyPadding;

  /// The padding for the actions section.
  final EdgeInsetsGeometry? actionsPadding;

  /// The alignment for the actions.
  final MainAxisAlignment? actionsAlignment;

  final double? width;

  const DDialogContent({
    super.key,
    required this.title,
    this.body,
    this.actions,
    this.enableBackButton = false,
    this.titlePadding,
    this.bodyPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColorLight.surface,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Padding(
            padding: titlePadding ?? EdgeInsets.fromLTRB(32.w, 24.w, 32.w, 10.w),
            child: Row(
              mainAxisAlignment: enableBackButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (enableBackButton) 48.horizontalSpace,
                AppText(title, style: AppStyle.textBold32, textAlign: TextAlign.start),
                if (enableBackButton)
                  IconButton(
                    style: IconButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.back(),
                  ),
              ],
            ),
          ),

          // Content Section
          if (body != null && body!.isNotEmpty)
            Padding(
              padding: bodyPadding ?? EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: body!,
              ),
            ),

          // Actions Section
          if (actions != null && actions!.isNotEmpty)
            Padding(
              padding: actionsPadding ?? EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: actionsAlignment ?? MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows a dialog with customizable content.
///
/// Args:
///   context (BuildContext): BuildContext
///   dialogContent (Widget): The content widget of the dialog.
///   insetPadding (EdgeInsets): The padding of the dialog box.
///
void showDDialog(
  BuildContext context, {
  EdgeInsets? insetPadding,
  Color? backgroundColor,
  required Widget dialogContent,
}) {
  showGeneralDialog(
    useRootNavigator: false,
    barrierLabel: 'DDialog',
    context: context,
    transitionBuilder: (_, animation, _, child) {
      final curved = Curves.easeOutBack.transform(animation.value);
      return Transform.scale(
        scale: curved,
        child: Opacity(opacity: animation.value, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Dialog(
        backgroundColor: backgroundColor ?? Colors.transparent,
        insetPadding: insetPadding ?? EdgeInsets.all(20.w),
        child: dialogContent,
      );
    },
  );
}

/// Convenience method to show a dialog with title, body, and actions.
///
/// This is a wrapper around showDDiaLog that uses DDialogContent.
///
void showStandardDDiaLog(
  BuildContext context, {
  List<Widget>? body,
  List<Widget>? actions,
  EdgeInsetsGeometry? actionsPadding,
  EdgeInsetsGeometry? bodyPadding,
  EdgeInsets? insetPadding,
  MainAxisAlignment? actionsAlignment,
  required String title,
  bool enableBackButton = false,
  double? width,
}) {
  showDDialog(
    context,
    insetPadding: insetPadding,
    dialogContent: DDialogContent(
      title: title,
      body: body,
      actions: actions,
      enableBackButton: enableBackButton,
      actionsPadding: actionsPadding,
      bodyPadding: bodyPadding,
      actionsAlignment: actionsAlignment,
      width: width,
    ),
  );
}
