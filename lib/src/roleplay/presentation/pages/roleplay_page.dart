part of '../../roleplay.dart';

class RoleplayPage extends StatelessWidget {
  const RoleplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: BlocSelector<RoleplayCubit, RoleplayState, RoleplayStatus>(
        selector: (state) => state.status,
        builder: (context, status) {
          return switch (status) {
            RoleplayStatus.initial => const _RoleplayPageLoading(),
            RoleplayStatus.loading => const _RoleplayPageLoading(),
            RoleplayStatus.failure => const _RoleplayPageError(),
            RoleplayStatus.success => _RoleplayPageView(),
          };
        },
      ),
    );
  }
}

class _RoleplayPageView extends StatelessWidget {
  const _RoleplayPageView();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, SectionEntity>(
      selector: (state) => state.currentSection,
      builder: (context, currentSection) {
        final bool hasHeroImage = currentSection.image.isNotEmpty;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: hasHeroImage ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RoleplayHeroBackground(),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RoleplayPageHeader(
                        section: currentSection,
                        useLightContent: hasHeroImage,
                      ),
                      Expanded(
                        child: RoleplayContentList(
                          key: ValueKey(currentSection.id),
                          section: currentSection,
                        ),
                      ),
                      BlocSelector<RoleplayCubit, RoleplayState, bool>(
                        selector: (state) => state.isCurrentSectionRevealed,
                        builder: (context, isSectionReady) {
                          final bottomSpacing = SizedBox(height: 12.h + MediaQuery.paddingOf(context).bottom);
                          if (kDebugMode) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RoleplayBottomAction(currentSection: currentSection),
                                bottomSpacing,
                              ],
                            );
                          }
                          if (!isSectionReady) return bottomSpacing;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoleplayBottomAction(currentSection: currentSection),
                              bottomSpacing,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
  const _RoleplayPageError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocSelector<RoleplayCubit, RoleplayState, String>(
              selector: (state) => state.errorMessage ?? 'Something went wrong',
              builder: (context, errorMessage) {
                return AppText(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: AppStyle.text18.copyWith(color: AppCustomColor.textPrimary),
                );
              },
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
