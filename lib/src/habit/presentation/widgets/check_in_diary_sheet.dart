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
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(widget.userHabit.displayIcon, style: AppStyle.text40),
            16.verticalSpace,
            AppText(
              widget.userHabit.displayTitle,
              style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
            ),
            20.verticalSpace,
            AppText(
              context.l10n.habit.checkInAddNote,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
            ),
            8.verticalSpace,
            TextField(
              controller: _noteController,
              maxLines: 4,
              minLines: 3,
              maxLength: 1000,
              textInputAction: TextInputAction.newline,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.habit.checkInNotePlaceholder,
                hintStyle: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                counterText: '',
                filled: true,
                fillColor: AppCustomColor.backgroundGray,
                contentPadding: EdgeInsets.all(14.w),
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
            16.verticalSpace,
            DButton(
              text: context.l10n.habit.checkInSubmit,
              onPressed: _isSubmitting ? null : _checkIn,
            ),
          ],
        ),
      ),
    );
  }
}
