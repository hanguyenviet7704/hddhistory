part of '../../habit.dart';

/// Check-in + Diary bottom sheet (Figma `checkinDiary`, PRD §9.7). Opened by
/// tapping a habit's check circle on the tracker: icon + title + an optional
/// "Add note" textarea + "Check in". Submitting ticks today for the habit and
/// saves the note to the habit diary. Pops `true` on success.
class CheckInDiarySheet extends StatefulWidget {
  final UserHabitEntity userHabit;

  const CheckInDiarySheet({super.key, required this.userHabit});

  static Future<bool?> show(BuildContext context, {required UserHabitEntity userHabit}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: AppDI.injector.get<HabitCubit>(),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: CheckInDiarySheet(userHabit: userHabit),
        ),
      ),
    );
  }

  @override
  State<CheckInDiarySheet> createState() => _CheckInDiarySheetState();
}

class _CheckInDiarySheetState extends State<CheckInDiarySheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final ok = await context.read<HabitCubit>().checkIn(
      widget.userHabit.id,
      done: true,
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bake the bottom safe-area inset into the container's own padding
    // instead of wrapping in SafeArea — that keeps the white sheet flush to
    // the bottom edge (no gap exposing the plain, non-rounded page background
    // underneath) while content still clears the home indicator / Android nav
    // bar. Mirrors the same fix in edit_habit_sheet.dart.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(color: AppCustomColor.borderSecondary, borderRadius: BorderRadius.circular(30.r)),
            ),
          ),
          24.verticalSpace,
          HabitDomainIcon(
            skillsetId: widget.userHabit.habit?.skillsetId ?? '',
            size: 48,
          ),
          4.verticalSpace,
          AppText(
            widget.userHabit.displayTitle,
            style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
          ),
          24.verticalSpace,
          AppText(
            context.l10n.habit.checkInAddNote,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700),
          ),
          6.verticalSpace,
          SizedBox(
            height: 120.h,
            width: double.infinity,
            child: TextField(
              controller: _noteController,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              maxLength: 1000,
              textInputAction: TextInputAction.newline,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.habit.checkInNotePlaceholder,
                hintStyle: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                counterText: '',
                filled: true,
                fillColor: AppCustomColor.backgroundWhite,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppCustomColor.borderSecondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppCustomColor.brandPrimary),
                ),
              ),
            ),
          ),
          24.verticalSpace,
          DButton(
            text: context.l10n.habit.checkInSubmit,
            backgroundColor: AppCustomColor.brandPrimary,
            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textWhite),
            onPressed: _isSubmitting ? null : _checkIn,
          ),
        ],
      ),
    );
  }
}
