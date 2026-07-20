part of '../../warm_up.dart';

/// Figma 11242-49681 / 11242-49697 — question player. Deliberately thin: all
/// rendering is delegated to the existing [DailyWarmUpQuestionStep] /
/// [DailyWarmUpResultBottomSheet] widgets (progress dots, Check ->
/// correct/explain -> Continue), driven by [WarmUpState] projected into the
/// [DailyWarmUpState] shape those widgets expect. No daily_warm_up file is
/// modified to achieve this reuse.
class WarmUpQuestionPage extends StatefulWidget {
  const WarmUpQuestionPage({super.key});

  @override
  State<WarmUpQuestionPage> createState() => _WarmUpQuestionPageState();
}

class _WarmUpQuestionPageState extends State<WarmUpQuestionPage> {
  @override
  void initState() {
    super.initState();
    // Branch navigation doesn't fire the root route observer, so each warm-up
    // page sets its own (non-primary) route name to hide the shell's floating
    // nav (mirrors keypoint_complete_page). Runs after nav → wins.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.warmUpQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WarmUpCubit, WarmUpState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == WarmUpStatus.result && state.latestResult != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _showResultSheet(context, state);
          });
          return;
        }
        if (state.status == WarmUpStatus.completion) {
          WarmUpCompletionRoute().go(context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<WarmUpCubit>();
        return DailyWarmUpQuestionStep(
          state: state.asDailyWarmUpState,
          // Design item 11 — this is the return-refresher quiz (a distinct
          // flow from the daily_warm_up mini check-in that also renders
          // through this shared widget), so it alone opts into the study
          // background + glass question card.
          applyStudyTheme: true,
          onClose: () {
            cubit.closeFlow();
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

  Future<void> _showResultSheet(BuildContext context, WarmUpState state) async {
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
          context.read<WarmUpCubit>().continueFromResult();
        },
      ),
    );
  }
}
