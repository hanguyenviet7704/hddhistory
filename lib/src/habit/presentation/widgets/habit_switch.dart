part of '../../habit.dart';

/// Figma pill switch (component 1155:7475 / 1155:7481): a 40×24 track — brand
/// when on, border/default when off — with a white 20px thumb. Replaces the
/// Material [Switch] in the habit sheets so the control matches the design
/// (the Material one renders oversized with an outlined off-state).
class HabitSwitch extends StatelessWidget {
  const HabitSwitch({super.key, required this.value, this.onChanged, this.isLoading = false});

  final bool value;
  final ValueChanged<bool>? onChanged;
  // While a setActive request for THIS row is in flight: blocks re-tap (a
  // second tap here fires a second network call with no cubit-side guard,
  // unlike e.g. IapCubit.restorePurchases) and swaps the thumb for a spinner
  // so the row doesn't look inert during the round trip.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null && !isLoading,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (onChanged == null || isLoading)
            ? null
            : () {
                AppHaptic.select();
                onChanged!(!value);
              },
        // Keep the whole hit target comfortably tappable (44pt guideline)
        // while the visible track stays at the design's 40×24.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 40.w,
            height: 24.w,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: value ? Colors.white : AppCustomColor.brandPrimary,
                      ),
                    )
                  : Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
