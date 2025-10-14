part of '../helpers.dart';

enum MessageType {
  normal,
  question,
  info,
  danger,
  error,
  success;

  Color get color {
    return switch (this) {
      MessageType.normal => Colors.white,
      MessageType.info => Colors.blue,
      MessageType.error => Colors.red,
      MessageType.danger => Colors.orange,
      MessageType.success => Colors.green,
      MessageType.question => Colors.blue,
    };
  }

  Color get backgroundColor {
    return switch (this) {
      MessageType.normal => Colors.white,
      MessageType.info => Colors.blue.shade50,
      MessageType.error => Colors.red.shade50,
      MessageType.danger => Colors.orange.shade50,
      MessageType.success => Colors.green.shade50,
      MessageType.question => Colors.blue.shade50,
    };
  }

  Color get textColor {
    return switch (this) {
      MessageType.normal => Colors.black,
      MessageType.info => Colors.black,
      MessageType.error => Colors.black,
      MessageType.danger => Colors.black,
      MessageType.success => Colors.black,
      MessageType.question => Colors.black,
    };
  }

  Color get borderColor {
    return switch (this) {
      MessageType.normal => Colors.grey.shade300,
      MessageType.info => Colors.blue,
      MessageType.error => Colors.red,
      MessageType.danger => Colors.orange,
      MessageType.success => Colors.green,
      MessageType.question => Colors.blue,
    };
  }

  IconData get icon {
    return switch (this) {
      MessageType.normal => Icons.info_rounded,
      MessageType.info => Icons.info_rounded,
      MessageType.error => Icons.error_rounded,
      MessageType.danger => Icons.warning_rounded,
      MessageType.success => Icons.check_circle_rounded,
      MessageType.question => Icons.help_rounded,
    };
  }

  String get svgIcon {
    return switch (this) {
      MessageType.normal => AppAsset.svg.common.window,
      MessageType.info => AppAsset.svg.common.info,
      MessageType.error => AppAsset.svg.common.error,
      MessageType.danger => AppAsset.svg.common.error,
      MessageType.success => AppAsset.svg.common.success,
      MessageType.question => AppAsset.svg.common.info,
    };
  }

  String get svgIconSquare {
    return switch (this) {
      MessageType.normal => AppAsset.svg.common.window,
      MessageType.info => AppAsset.svg.common.info,
      MessageType.error => AppAsset.svg.common.error,
      MessageType.danger => AppAsset.svg.common.error,
      MessageType.success => AppAsset.svg.common.success,
      MessageType.question => AppAsset.svg.common.info,
    };
  }

  String get title {
    return switch (this) {
      MessageType.normal => 'notificationTitle',
      MessageType.info => 'infoTitle',
      MessageType.error => 'errorTitle',
      MessageType.danger => 'warningTitle',
      MessageType.success => 'successTitle',
      MessageType.question => 'questionTitle',
    };
  }
}

mixin DDialog {
  static void show({
    List<Widget> body = const [],
    EdgeInsetsGeometry? actionsPadding,
    EdgeInsets? insetPadding,
    MainAxisAlignment? actionsAlignment,
    AlignmentGeometry messageAlignment = Alignment.center,
    String title = '',
    String message = '',
    String acceptText = '',
    bool scrollable = false,
    bool enableTopBackButton = false,
    double elevation = 100,
    VoidCallback? onBack,
  }) {
    assert(body.isNotEmpty || message.isNotEmpty, 'body or message must not be empty');

    title = title.isNotEmpty ? title : 'notificationTitle';
    acceptText = acceptText.isNotEmpty ? acceptText : 'accept';

    showDialog(
      useRootNavigator: false,
      barrierLabel: 'DDialog',
      context: AppConfig.instance.context!,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
          backgroundColor: Colors.white,
          elevation: elevation,
          alignment: messageAlignment,
          scrollable: scrollable,
          actionsPadding: actionsPadding ?? const EdgeInsets.fromLTRB(0, 15, 0, 0),
          contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          titlePadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
          // buttonPadding: const EdgeInsets.all(10),
          surfaceTintColor: AppTheme.surface,
          insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actionsAlignment: actionsAlignment,
          title: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: enableTopBackButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (enableTopBackButton) const SizedBox(width: 48),
              AppText(title, style: AppStyle.textBold20),
              if (enableTopBackButton)
                IconButton(
                  style: IconButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: message.isNotEmpty ? [AppText(message)] : body,
          ),
          actions: [
            DButton(
              text: acceptText,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
              onPressed: onBack ?? DNavigator.back,
            ),
          ],
        );
      },
    );
  }

  static void showTwoOption({
    List<Widget> body = const [],
    List<Widget> actions = const [],
    EdgeInsetsGeometry? actionsPadding,
    EdgeInsets? insetPadding,
    MainAxisAlignment? actionsAlignment,
    AlignmentGeometry messageAlignment = Alignment.center,
    bool scrollable = false,
    bool enableTopBackButton = false,
    double elevation = 100,
    String title = '',
    String message = '',
    String acceptText = '',
    String cancelText = '',
    VoidCallback? onAccept,
    VoidCallback? onCancel,
  }) {
    assert(body.isNotEmpty || message.isNotEmpty, 'body or message must not be empty');

    title = title.isNotEmpty ? title : 'notificationTitle';

    acceptText = acceptText.isNotEmpty ? acceptText : 'accept';
    cancelText = cancelText.isNotEmpty ? cancelText : 'cancel';

    showDialog(
      useRootNavigator: false,
      barrierLabel: 'DDialog',
      context: AppConfig.instance.context!,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
          backgroundColor: Colors.white,
          elevation: elevation,
          alignment: messageAlignment,
          scrollable: scrollable,
          actionsPadding: actionsPadding ?? const EdgeInsets.fromLTRB(0, 15, 0, 0),
          contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          titlePadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
          // buttonPadding: const EdgeInsets.all(10),
          surfaceTintColor: AppTheme.surface,
          insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actionsAlignment: actionsAlignment,
          title: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: enableTopBackButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (enableTopBackButton) const SizedBox(width: 48),
              AppText(title, style: AppStyle.textBold20),
              if (enableTopBackButton)
                IconButton(
                  style: IconButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: message.isNotEmpty ? [AppText(message)] : body,
          ),
          actions: [
            Row(
              children: [
                DButton(
                  text: cancelText,
                  expandedFlex: 1,
                  backgroundColor: MessageType.error.color,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10))),
                  onPressed: onCancel ?? DNavigator.back,
                ),
                DButton(
                  text: acceptText,
                  expandedFlex: 1,
                  backgroundColor: MessageType.success.color,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(10))),
                  onPressed: onAccept ?? DNavigator.back,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void custom({
    required List<Widget> body,
    List<Widget> actions = const [],
    EdgeInsetsGeometry? actionsPadding,
    EdgeInsets? insetPadding,
    MainAxisAlignment? actionsAlignment,
    AlignmentGeometry messageAlignment = Alignment.center,
    String title = '',
    bool scrollable = false,
    bool enableTopBackButton = false,
    double elevation = 100,
    VoidCallback? onBack,
  }) {
    assert(body.isNotEmpty, 'body must not be empty');

    title = title.isNotEmpty ? title : 'notificationTitle';

    showDialog(
      useRootNavigator: false,
      barrierLabel: 'DDialog',
      context: AppConfig.instance.context!,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
          backgroundColor: Colors.white,
          elevation: elevation,
          alignment: messageAlignment,
          scrollable: scrollable,
          actionsPadding: actionsPadding ?? const EdgeInsets.fromLTRB(0, 15, 0, 0),
          contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          titlePadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
          // buttonPadding: const EdgeInsets.all(10),
          surfaceTintColor: AppTheme.surface,
          insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actionsAlignment: actionsAlignment,
          title: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: enableTopBackButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (enableTopBackButton) const SizedBox(width: 48),
              AppText(title, style: AppStyle.textBold20),
              if (enableTopBackButton)
                IconButton(
                  style: IconButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: body,
          ),
          actions: actions.isNotEmpty && !enableTopBackButton
              ? actions
              : [
                  DButton(
                    text: 'OK',
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
                    onPressed: onBack ?? DNavigator.back,
                  ),
                ],
        );
      },
    );
  }
}

mixin DMessage {
  static void showSnackBar({
    String message = '',
    Widget? messageWidget,
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double elevation = 0,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder? shape,
    bool showCloseIcon = true,
    Color? closeIconColor,
    double? width,
  }) {
    ScaffoldMessenger.of(AppConfig.instance.context!).showSnackBar(
      SnackBar(
        content: InkWell(onTap: onTap, child: messageWidget ?? AppText(message, style: AppStyle.text14.copyWith(color: type.color))),
        backgroundColor: type.backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        dismissDirection: dismissDirection ?? DismissDirection.up,
        margin: margin ?? EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        elevation: elevation,
        onVisible: onVisible ?? () {},
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: type.borderColor, width: 1)),
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        width: width,
      ),
    );
  }

  static void showMessage({
    String message = '',
    MessageType type = MessageType.info,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    double elevation = 1.5,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    bool showCloseIcon = true,
    Color? closeIconColor,
    double? width,
    AlignmentGeometry messageAlignment = Alignment.topCenter,
    double leadingSpace = 8,
    double trailingSpace = 14,
  }) {
    DOverlay.showOverlay(
      context: AppConfig.instance.context!,
      child: OverlayMessage(
        message: message,
        type: type,
        duration: duration,
        action: action,
        margin: margin,
        padding: padding,
        elevation: elevation,
        dismissDirection: dismissDirection,
        onVisible: onVisible,
        onTap: onTap,
        shape: shape,
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        width: width,
        messageAlignment: messageAlignment,
        leadingSpace: leadingSpace,
        trailingSpace: trailingSpace,
      ),
    );
  }

  static void customMessage({
    Widget? messageWidget,
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    double elevation = 1.5,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    double? width,
    AlignmentGeometry messageAlignment = Alignment.topCenter,
    double leadingSpace = 10,
    double trailingSpace = 14,
  }) {
    DOverlay.showOverlay(
      context: AppConfig.instance.context!,
      child: OverlayMessage(
        messageWidget: messageWidget,
        type: type,
        duration: duration,
        action: action,
        margin: margin,
        padding: padding,
        elevation: elevation,
        dismissDirection: dismissDirection,
        onVisible: onVisible,
        onTap: onTap,
        shape: shape,
        width: width,
        messageAlignment: messageAlignment,
        leadingSpace: leadingSpace,
        trailingSpace: trailingSpace,
      ),
    );
  }
}

extension DMessageHelper on BuildContext {
  void showDSnackBar({
    String message = '',
    Widget? messageWidget,
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double elevation = 0,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder? shape,
    bool showCloseIcon = true,
    Color? closeIconColor,
    double? width,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: InkWell(onTap: onTap, child: messageWidget ?? AppText(message, style: AppStyle.text14.copyWith(color: type.color))),
        backgroundColor: type.backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        dismissDirection: dismissDirection ?? DismissDirection.up,
        margin: margin ?? EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        elevation: elevation,
        onVisible: onVisible ?? () {},
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: type.borderColor, width: 1)),
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        width: width,
      ),
    );
  }

  void showDMessage({
    String message = '',
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    double elevation = 1.5,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    bool showCloseIcon = true,
    Color? closeIconColor,
    double? width,
    AlignmentGeometry messageAlignment = Alignment.topCenter,
    double leadingSpace = 10,
    double trailingSpace = 14,
  }) {
    DOverlay.showOverlay(
      context: this,
      child: OverlayMessage(
        message: message,
        type: type,
        duration: duration,
        action: action,
        margin: margin,
        padding: padding,
        elevation: elevation,
        dismissDirection: dismissDirection,
        onVisible: onVisible,
        onTap: onTap,
        shape: shape,
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        width: width,
        messageAlignment: messageAlignment,
        leadingSpace: leadingSpace,
        trailingSpace: trailingSpace,
      ),
    );
  }

  void customMessage({
    Widget? messageWidget,
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    double elevation = 1.5,
    DismissDirection? dismissDirection,
    VoidCallback? onVisible,
    VoidCallback? onTap,
    ShapeBorder shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    double? width,
    AlignmentGeometry messageAlignment = Alignment.topCenter,
    double leadingSpace = 10,
    double trailingSpace = 14,
  }) {
    DOverlay.showOverlay(
      context: this,
      child: OverlayMessage(
        messageWidget: messageWidget,
        type: type,
        duration: duration,
        action: action,
        margin: margin,
        padding: padding,
        elevation: elevation,
        dismissDirection: dismissDirection,
        onVisible: onVisible,
        onTap: onTap,
        shape: shape,
        width: width,
        messageAlignment: messageAlignment,
        leadingSpace: leadingSpace,
        trailingSpace: trailingSpace,
      ),
    );
  }

  void showDMaterialBanner({
    String message = '',
    Widget? messageWidget,
    MessageType type = MessageType.normal,
    Duration duration = const Duration(milliseconds: 1500),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Widget? leading,
    double elevation = 2,
    VoidCallback? onVisible,
    ShapeBorder? shape,
    bool showCloseIcon = true,
    bool forceActionsBelow = false,
    Color? closeIconColor,
    Color? dividerColor,
    double? width,
  }) {
    ScaffoldMessenger.of(this).showMaterialBanner(
      MaterialBanner(
        content: messageWidget ?? AppText(message, textAlign: TextAlign.justify),
        backgroundColor: type.color,
        leading: leading ?? SvgPicture.asset(type.svgIcon, width: 20, height: 20),
        margin: margin ?? EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w),
        leadingPadding: padding ?? EdgeInsets.only(right: 15.w),
        dividerColor: dividerColor,
        forceActionsBelow: forceActionsBelow,
        actions: [
          if (action != null)
            TextButton(
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
          const SizedBox.shrink(),
        ],
        elevation: elevation,
        onVisible: onVisible ?? () {},
      ),
    );

    Future.delayed(duration, () {
      ScaffoldMessenger.of(this).clearMaterialBanners();
    });
  }
}
