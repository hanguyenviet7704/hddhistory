part of '../../roleplay.dart';

class RoleplayPage extends StatelessWidget {
  const RoleplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: BlocBuilder<RoleplayCubit, RoleplayState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.currentRoleplay.image != current.currentRoleplay.image ||
            previous.currentLesson != current.currentLesson ||
            previous.errorMessage != current.errorMessage,
        builder: (context, state) {
          return switch (state.status) {
            RoleplayStatus.initial || RoleplayStatus.loading => const _RoleplayPageLoading(),
            RoleplayStatus.failure => _RoleplayPageError(message: state.errorMessage),
            RoleplayStatus.success => _RoleplayPageView(
              heroImageUrl: state.currentRoleplay.image,
              lessonTitle: state.currentLesson.title.text,
            ),
          };
        },
      ),
    );
  }
}

class _RoleplayPageView extends StatelessWidget {
  final String heroImageUrl;
  final String lessonTitle;

  const _RoleplayPageView({
    required this.heroImageUrl,
    required this.lessonTitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasHeroImage = heroImageUrl.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHeroImage ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RoleplayHeroBackground(imageUrl: heroImageUrl),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RoleplayPageHeader(
                  title: lessonTitle,
                  useLightContent: hasHeroImage,
                ),
                const RoleplayContent(),
              ],
            ),
          ),
        ],
      ),
    );
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

  const _RoleplayPageError({
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = (message?.isNotEmpty ?? false)
        ? message!
        : context.text.common.errorOopsSomethingWentWrongWhileLoading;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppStyle.text18.copyWith(color: AppCustomColor.textPrimary),
            ),
            16.verticalSpace,
            DButton(
              onPressed: () => context.pop(),
              text: context.text.common.close,
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
