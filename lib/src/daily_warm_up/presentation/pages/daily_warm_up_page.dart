part of '../../daily_warm_up.dart';

class DailyWarmUpPage extends StatelessWidget {
  const DailyWarmUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyWarmUpCubit, DailyWarmUpState>(
      listenWhen: (previous, current) {
        return previous.status != current.status ||
            previous.latestResult != current.latestResult ||
            previous.suggestedCourse != current.suggestedCourse ||
            previous.hasMarkedShown != current.hasMarkedShown;
      },
      listener: _handleStateChanged,
      builder: (context, state) {
        final cubit = context.read<DailyWarmUpCubit>();
        return switch (state.status) {
          DailyWarmUpStatus.entry => DailyWarmUpEntryStep(
            onStart: cubit.startWarmUp,
            onMaybeLater: () async {
              await cubit.dismissEntry();
              if (!context.mounted) return;
              _closeRoute(context);
            },
          ),
          DailyWarmUpStatus.question || DailyWarmUpStatus.result => DailyWarmUpQuestionStep(
            state: state,
            onClose: () {
              cubit.closeFlow();
              _closeRoute(context);
            },
            onCheck: () => cubit.checkCurrentQuestion(),
            onSelectChoice: cubit.selectChoiceAnswer,
            onSetOrderedOptionIds: cubit.setOrderedOptionIds,
            onPlaceOption: (slotIndex, optionId) => cubit.placeOption(slotIndex: slotIndex, optionId: optionId),
            onRemovePlacedOption: cubit.removePlacedOption,
            onToggleWordIndex: cubit.toggleWordIndex,
          ),
          DailyWarmUpStatus.completion => DailyWarmUpCompletionStep(
            state: state,
            onStartLesson: () async {
              final canRoute = await cubit.startTodayLesson();
              if (!context.mounted) return;
              if (canRoute) {
                context.read<PageCubit>().requestHomeBranchResetOnNextSelection();
                CourseRoadmapRoute().go(context);
                return;
              }
              cubit.closeFlow();
              _closeRoute(context);
            },
            onExploreMore: () async {
              await cubit.exploreMore();
              if (context.mounted) _closeRoute(context);
            },
          ),
          _ => const Scaffold(body: SizedBox.shrink()),
        };
      },
    );
  }

  void _handleStateChanged(BuildContext context, DailyWarmUpState state) {
    final cubit = context.read<DailyWarmUpCubit>();

    if (state.status == DailyWarmUpStatus.entry && !state.hasMarkedShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) cubit.markEntryPresented();
      });
    }

    if (state.status == DailyWarmUpStatus.result && state.latestResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showResultSheet(
          context,
          state.latestResult!,
          question: state.currentQuestion,
          explanationText: state.currentQuestion?.explanationText ?? '',
        );
      });
    }

    if (state.status == DailyWarmUpStatus.completion && state.suggestedCourse == null && !state.isLoadingCourse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) cubit.loadSuggestedCourse();
      });
    }
  }

  Future<void> _showResultSheet(
    BuildContext context,
    DailyWarmUpAnswerResultEntity result, {
    required QuestionEntity? question,
    required String explanationText,
  }) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DailyWarmUpResultBottomSheet(
        result: result,
        question: question,
        explanationText: explanationText,
        onContinue: () {
          Navigator.of(sheetContext).pop();
          context.read<DailyWarmUpCubit>().continueFromResult();
        },
      ),
    );
  }

  void _closeRoute(BuildContext context) {
    if (context.canPop()) context.pop();
  }
}
