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
      child: BlocBuilder<OnboardBranchingCubit, OnboardBranchingState>(
        builder: (context, state) {
          if (state.status == OnboardBranchingStatus.loading && state.onboardScenarioData.scenes.isEmpty) {
            return const Scaffold(
              backgroundColor: Color(0xFFF3F2F8),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final body = switch (state.stage) {
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

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: _buildBackgroundDecoration(state),
              child: SafeArea(child: body),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(OnboardBranchingState state) {
    final isActivationContent = state.stage == OnboardBranchingStage.content && state.hasCurrentContent && state.currentContent.type == OnboardingContentType.activation;

    if (state.stage == OnboardBranchingStage.loading || isActivationContent) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5953EA),
            Color(0xFF838AF2),
          ],
        ),
      );
    }

    return const BoxDecoration(color: Color(0xFFF3F2F8));
  }

  Widget _buildContentStage(BuildContext context, OnboardBranchingState state) {
    if (!state.hasCurrentContent) {
      return _buildContentFallbackView(context);
    }

    final content = state.currentContent;
    final cubit = context.read<OnboardBranchingCubit>();

    switch (content.type) {
      case OnboardingContentType.branch:
        final branch = content.branch;
        if (branch == null) return _buildContentFallbackView(context);
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
        if (fixed == null) return _buildContentFallbackView(context);
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
        if (personAdmire == null) return _buildContentFallbackView(context);
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
        if (selectedOption == null) return _buildContentFallbackView(context);
        return OnboardBranchingPersonAdmireDetailView(
          option: selectedOption,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.activation:
        final activation = content.activation;
        if (activation == null) return _buildContentFallbackView(context);
        return OnboardBranchingActivationView(
          activation: activation,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.fact:
        final fact = content.fact;
        if (fact == null) return _buildContentFallbackView(context);
        return OnboardBranchingFactView(
          fact: fact,
          onContinue: cubit.continueCurrentContent,
        );
      case OnboardingContentType.unknown:
        return _buildContentFallbackView(context);
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
          // See onboard_v2_course_picker_page.dart's identical pairing: without
          // this, PageCubit.currentRouteName never becomes courseRoadmap for
          // this onboarding path, silently breaking the re-anchor prompt and
          // the floating bottom nav's visibility for the user's first course.
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
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

  Widget _buildContentFallbackView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2.4),
            ),
            12.verticalSpace,
            AppText(
              context.l10n.onboarding.onboardingLoadingPersonalizationText,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.text14.copyWith(
                color: const Color(0xB3110751),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
