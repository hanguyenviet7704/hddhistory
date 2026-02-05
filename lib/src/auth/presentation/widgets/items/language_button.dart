part of '../../../auth.dart';

class LanguageBtn extends StatelessWidget {
  final Widget child;
  final bool enableBack;
  const LanguageBtn({super.key, required this.child, this.enableBack = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, AppLocale>(
      builder: (context, state) {
        return PopupMenuButton(
          color: AppColorLight.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          itemBuilder: (context) {
            return AppLocale.values
                .map(
                  (e) => PopupMenuItem(
                    value: e,
                    child: LanguageItem(locale: e, isSelected: e == state),
                  ),
                )
                .toList();
          },
          onSelected: (value) async {
            AppService.instance.appTrackingService.trackProfileLanguageSelect(value.label);
            if (value == state) return;
            context.read<LocaleCubit>().setLocale(value);
            // context.read<HandfeelingCubit>().getBrushes();
            if (enableBack) context.back();
          },
          onOpened: () => AppService.instance.appTrackingService.trackProfileLanguageView(),
          child: child,
        );
      },
    );
  }
}

class LanguageItem extends StatelessWidget {
  final AppLocale locale;
  final bool isSelected;

  const LanguageItem({
    super.key,
    required this.locale,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // Flag Icon
          SvgPicture.asset(
            locale.flagCircle,
            width: 32.r,
            height: 32.r,
          ),
          20.horizontalSpace,

          // Language Name
          Expanded(
            child: AppText(
              locale.label,
              style: AppStyle.text20.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.blue,
                height: 1.4,
              ),
            ),
          ),

          // Check Icon (only show when selected)
          if (isSelected) ...[
            20.horizontalSpace,
            Icon(
              Icons.check_rounded,
              size: 32.r,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }
}
