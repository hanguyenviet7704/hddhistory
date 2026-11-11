part of '../../spaced_review.dart';

/// "Ôn tập hôm nay" question player. Like `WarmUpQuestionPage`, all rendering
/// is delegated to the daily-warm-up player widgets, driven by
/// [SpacedReviewState] projected into the [DailyWarmUpState] shape they expect.
class SpacedReviewQuestionPage extends StatefulWidget {
  const SpacedReviewQuestionPage({super.key});

  @override
  State<SpacedReviewQuestionPage> createState() => _SpacedReviewQuestionPageState();
}

class _SpacedReviewQuestionPageState extends State<SpacedReviewQuestionPage> {
  @override
  void initState() {
    super.initState();
    // Non-primary route name → hides the shell's floating nav (branch
    // navigation doesn't fire the root route observer).
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.spacedReviewQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpacedReviewCubit, SpacedReviewState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SpacedReviewStatus.result && state.latestResult != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _showResultSheet(context, state);
          });
          return;
        }
        if (state.status == SpacedReviewStatus.completion) {
          SpacedReviewCompletionRoute().pushReplacement(context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SpacedReviewCubit>();
        return DailyWarmUpQuestionStep(
          state: state.asDailyWarmUpState,
          applyStudyTheme: true,
          onClose: () {
            unawaited(cubit.closeFlow());
            if (context.canPop()) context.pop();
          },
          onCheck: cubit.checkCurrentQuestion,
          onSelectChoice: cubit.selectChoiceAnswer,
          onSetOrderedOptionIds: cubit.setOrderedOptionIds,
          onPlaceOption: (slotIndex, optionId) => cubit.placeOption(slotIndex: slotIndex, optionId: optionId),
          onRemovePlacedOption: cubit.removePlacedOption,
          onToggleWordIndex: cubit.toggleWordIndex,
        );
      },
    );
  }

  Future<void> _showResultSheet(BuildContext context, SpacedReviewState state) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final result = state.latestResult;
    if (result == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DailyWarmUpResultBottomSheet(
        result: result,
        question: state.currentQuestion,
        explanationText: state.currentQuestion?.explanationText ?? '',
        onContinue: () {
          Navigator.of(sheetContext).pop();
          unawaited(context.read<SpacedReviewCubit>().continueFromResult());
        },
      ),
    );
  }
}
