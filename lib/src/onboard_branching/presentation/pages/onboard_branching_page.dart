part of '../../onboard_branching.dart';

class OnboardBranchingPage extends StatefulWidget {
  const OnboardBranchingPage({
    super.key,
    this.userName = '',
  });

  final String userName;

  @override
  State<OnboardBranchingPage> createState() => _OnboardBranchingPageState();
}

class _OnboardBranchingPageState extends State<OnboardBranchingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardBranchingCubit>().initializeFlow(userName: widget.userName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardBranchingCubit, OnboardBranchingState>(
      listenWhen: (previous, current) => previous.p7ErrorMessage != current.p7ErrorMessage && current.p7ErrorMessage != null,
      listener: (context, state) {
        DMessage.showMessage(type: MessageType.error, message: state.p7ErrorMessage ?? '');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Onboarding'),
        ),
        body: SafeArea(
          child: BlocBuilder<OnboardBranchingCubit, OnboardBranchingState>(
            builder: (context, state) {
              if (state.status == OnboardBranchingStatus.loading && state.onboardScenarioData.scenes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return switch (state.stage) {
                OnboardBranchingStage.welcome => OnboardBranchingWelcomeView(
                  userName: state.userName,
                  onContinue: context.read<OnboardBranchingCubit>().continueFromWelcome,
                ),
                OnboardBranchingStage.content => _buildContentStage(context, state),
                OnboardBranchingStage.loading => OnboardBranchingLoadingView(
                  onCompleted: context.read<OnboardBranchingCubit>().onLoadingCompleted,
                ),
                OnboardBranchingStage.recommendation => _buildRecommendationStage(context, state),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentStage(BuildContext context, OnboardBranchingState state) {
    if (!state.hasCurrentContent) {
      return const SizedBox.shrink();
    }

    final content = state.currentContent;
    final cubit = context.read<OnboardBranchingCubit>();

    switch (content.type) {
      case OnboardingContentType.branch:
        final branch = content.branch;
        if (branch == null) return const SizedBox.shrink();
        return OnboardBranchingOptionContentView(
          title: branch.question.text,
          subTitle: branch.subQuestion.text,
          options: branch.options
              .map(
                (option) => OnboardBranchingOptionDisplayItem(
                  id: option.id.toString(),
                  label: option.label.text,
                  icon: option.icon,
                ),
              )
              .toList(),
          selectedOptionId: state.selectedCurrentBranchOption?.id.toString(),
          onSelect: (optionId) {
            final option = branch.options.firstWhere(
              (item) => item.id.toString() == optionId,
              orElse: () => const OnboardingScenarioBranchOptionEntity(),
            );
            if (option.id == 0) return;
            cubit.selectBranchOption(option);
          },
          continueEnabled: state.canContinueCurrentContent,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.fixed:
        final fixed = content.fixed;
        if (fixed == null) return const SizedBox.shrink();
        return OnboardBranchingOptionContentView(
          title: fixed.question.text,
          subTitle: fixed.subQuestion.text,
          options: fixed.options
              .map(
                (option) => OnboardBranchingOptionDisplayItem(
                  id: option.id.toString(),
                  label: option.label.text,
                  icon: option.icon,
                ),
              )
              .toList(),
          selectedOptionId: state.selectedCurrentFixedOption?.id.toString(),
          onSelect: (optionId) {
            final option = fixed.options.firstWhere(
              (item) => item.id.toString() == optionId,
              orElse: () => const OnboardOptionEntity(),
            );
            if (option.id == 0) return;
            cubit.selectFixedOption(option);
          },
          continueEnabled: state.canContinueCurrentContent,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.personAdmire:
        final personAdmire = content.personAdmire;
        if (personAdmire == null) return const SizedBox.shrink();
        if (!state.isPersonAdmireDetailVisible) {
          return OnboardBranchingPersonAdmireSelectView(
            question: personAdmire.question.text,
            subQuestion: personAdmire.subQuestion.text,
            options: personAdmire.options,
            selectedOptionName: state.selectedPersonAdmireOption?.name,
            onSelect: cubit.selectPersonAdmireOption,
            continueEnabled: state.canContinueCurrentContent,
            onContinue: cubit.continueCurrentContent,
          );
        }
        final selectedOption = state.selectedPersonAdmireOption;
        if (selectedOption == null) return const SizedBox.shrink();
        return OnboardBranchingPersonAdmireDetailView(
          option: selectedOption,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.activation:
        final activation = content.activation;
        if (activation == null) return const SizedBox.shrink();
        return OnboardBranchingActivationView(
          activation: activation,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.fact:
        final fact = content.fact;
        if (fact == null) return const SizedBox.shrink();
        return OnboardBranchingFactView(
          fact: fact,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecommendationStage(BuildContext context, OnboardBranchingState state) {
    final cubit = context.read<OnboardBranchingCubit>();

    return OnboardBranchingRecommendationView(
      percent: state.recommendedProgressPercent,
      course: state.recommendedCourse,
      isLoadingTryNow: state.isTryNowLoading,
      onTryNow: () async {
        final action = await cubit.onTryNowPressed();
        if (!context.mounted) return;
        if (action == OnboardBranchingTryNowAction.goCourseRoadmap) {
          CourseRoadmapRoute().go(context);
          return;
        }
        if (action == OnboardBranchingTryNowAction.goCoursePage) {
          CourseRoute().go(context);
        }
      },
      onChooseMyself: () {
        cubit.onChooseMyselfPressed();
        CourseRoute().go(context);
      },
    );
  }
}
