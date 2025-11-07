part of '../../roleplay.dart';

class RoleplayIntroPage extends StatelessWidget {
  const RoleplayIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: BlocBuilder<RoleplayCubit, RoleplayState>(
          builder: (context, state) {
            switch (state.status) {
              case RoleplayStatus.initial:
              case RoleplayStatus.loading:
                return const _RoleplayIntroLoading();
              case RoleplayStatus.failure:
                return _RoleplayIntroError(message: state.errorMessage);
              case RoleplayStatus.success:
                return _RoleplayIntroView(learningItem: state.currentLearningItem);
            }
          },
        ),
      ),
    );
  }
}

class _RoleplayIntroView extends StatelessWidget {
  final LearningItemEntity learningItem;

  const _RoleplayIntroView({required this.learningItem});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RoleplayIntroBackground(imageUrl: learningItem.image),
        SafeArea(
          child: Column(
            children: [
              _RoleplayIntroHeader(onClose: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      24.verticalSpace,
                      Align(
                        alignment: Alignment.center,
                        child: RoleplayIntroHeroCard(imageUrl: learningItem.image),
                      ),
                      32.verticalSpace,
                      RoleplayIntroDetails(
                        title: learningItem.title.text,
                        duration: _resolveDuration(),
                        description: _resolveDescription(),
                      ),
                    ],
                  ),
                ),
              ),
              RoleplayIntroActionButton(
                label: 'Start conversation',
                onPressed: () => RoleplayRoute().go(context),
              ),
              SizedBox(height: 12.h + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ],
    );
  }

  String _resolveDuration() {
    if (learningItem.sections.isEmpty) return '';
    return learningItem.sections.first.transition;
  }

  String _resolveDescription() {
    for (final section in learningItem.sections) {
      for (final content in section.contents) {
        if (content.type == RoleplaySectionType.leadingText && content.leadingText.content.isNotEmpty) {
          return content.leadingText.content;
        }
      }
      if (section.transition.isNotEmpty) {
        return section.transition;
      }
    }

    if (learningItem.documents.isNotEmpty) {
      final document = learningItem.documents.first;
      if (document.speechBubble.isNotEmpty) {
        return document.speechBubble;
      }
    }

    return learningItem.title.text;
  }
}

class _RoleplayIntroHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _RoleplayIntroHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(40.r),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AppAsset.svg.app.icClose,
              width: 16.w,
              height: 16.w,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleplayIntroLoading extends StatelessWidget {
  const _RoleplayIntroLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RoleplayIntroError extends StatelessWidget {
  final String? message;

  const _RoleplayIntroError({this.message});

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
              style: AppStyle.text18.copyWith(color: AppCustomColor.textWhite),
            ),
            16.verticalSpace,
            DButton(
              onPressed: () => context.pop(),
              text: 'Try again',
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
