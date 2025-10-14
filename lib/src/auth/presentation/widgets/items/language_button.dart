part of '../widgets.dart';

class LanguageBtn extends StatelessWidget {
  final Widget child;
  final bool enableBack;
  const LanguageBtn({super.key, required this.child, this.enableBack = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleType>(
      builder: (context, state) {
        return PopupMenuButton(
          color: AppColorLight.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          itemBuilder: (context) {
            return LocaleType.values
                .map(
                  (e) => PopupMenuItem(
                    value: e,
                    child: LanguageItem(localeType: e, isSelected: e == state),
                  ),
                )
                .toList();
          },
          onSelected: (value) {
            AppService.instance.appTrackingServiceNew.trackProfileLanguageSelect(value.label);
            if (value == state) return;
            context.read<LocaleCubit>().changeLocale(value);
            // context.read<HandfeelingCubit>().getBrushes();
            if (enableBack) context.back();
          },
          onOpened: () => AppService.instance.appTrackingServiceNew.trackProfileLanguageView(),
          child: child,
        );
      },
    );
  }
}

class LanguageItem extends StatelessWidget {
  final LocaleType localeType;
  final bool isSelected;

  const LanguageItem({
    super.key,
    required this.localeType,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isSelected ? AppCustomColor.neutral100 : Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // Flag Icon
          SvgPicture.asset(
            localeType.flagCircle,
            width: 32.r,
            height: 32.r,
          ),
          20.horizontalSpace,

          // Language Name
          Expanded(
            child: AppText(
              localeType.label,
              style: AppStyle.text20.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: AppCustomColor.secondary,
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
              color: AppCustomColor.orange,
            ),
          ],
        ],
      ),
    );
  }
}
