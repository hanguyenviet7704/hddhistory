part of '../../daily_warm_up.dart';

class DailyWarmUpBottomCta extends StatelessWidget {
  const DailyWarmUpBottomCta({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = enabled ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF);
    final foreground = enabled ? Colors.white : const Color(0xFF7F8EA4);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            onPressed: enabled && !isLoading ? onPressed : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: background,
              disabledForegroundColor: foreground,
              backgroundColor: background,
              foregroundColor: foreground,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : AppText(
                    label,
                    style: AppStyle.text16.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
