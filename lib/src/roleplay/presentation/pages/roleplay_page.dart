part of '../../roleplay.dart';

class RoleplayPage extends StatelessWidget {
  const RoleplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: BlocBuilder<RoleplayCubit, RoleplayState>(
        buildWhen: (previous, current) =>
            previous.status != current.status || previous.currentLearningItem != current.currentLearningItem || previous.errorMessage != current.errorMessage,
        builder: (context, state) {
          switch (state.status) {
            case RoleplayStatus.initial:
            case RoleplayStatus.loading:
              return const _RoleplayPageLoading();
            case RoleplayStatus.failure:
              return _RoleplayPageError(message: state.errorMessage);
            case RoleplayStatus.success:
              return _RoleplayPageView(
                learningItem: state.currentLearningItem,
                section: state.currentSection,
                sectionIndex: state.currentSectionIndex,
              );
          }
        },
      ),
    );
  }
}

class _RoleplayPageView extends StatelessWidget {
  final LearningItemEntity learningItem;
  final SectionEntity section;
  final int sectionIndex;

  const _RoleplayPageView({
    required this.learningItem,
    required this.section,
    required this.sectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasHeroImage = section.image.isNotEmpty;
    final SectionEntity? nextSection = sectionIndex + 1 < learningItem.sections.length ? learningItem.sections[sectionIndex + 1] : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHeroImage ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RoleplayHeroBackground(imageUrl: section.image),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleplayPageHeader(
                    section: section,
                    useLightContent: hasHeroImage,
                  ),
                  Expanded(
                    child: RoleplayContentList(
                      key: ValueKey(section.id),
                      section: section,
                    ),
                  ),
                  RoleplayBottomAction(
                    currentSection: section,
                    nextSection: nextSection,
                    onPressed: _buildCtaHandler(context, section, nextSection),
                  ),
                  SizedBox(height: 12.h + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _buildCtaHandler(
    BuildContext context,
    SectionEntity section,
    SectionEntity? nextSection,
  ) {
    final bool isExerciseSection = section.contents.isNotEmpty && section.contents.last.type == RoleplaySectionType.exercise;

    if (isExerciseSection) {
      return () {};
    }

    if (nextSection == null) {
      return null;
    }

    return () => context.read<RoleplayCubit>().goToNextSection();
  }
}

class _RoleplayPageLoading extends StatelessWidget {
  const _RoleplayPageLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RoleplayPageError extends StatelessWidget {
  final String? message;

  const _RoleplayPageError({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppStyle.text18.copyWith(color: AppCustomColor.textPrimary),
            ),
            16.verticalSpace,
            DButton(
              onPressed: () => context.pop(),
              text: 'Close',
              size: Size(180.w, 48.h),
              backgroundColor: AppCustomColor.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ],
        ),
      ),
    );
  }
}
