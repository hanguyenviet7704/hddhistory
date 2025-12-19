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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.read<RoleplayCubit>().state.currentRoleplay.image.isNotEmpty ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RoleplayHeroBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BlocSelector<RoleplayCubit, RoleplayState, bool>(
                  selector: (state) => state.currentRoleplay.image.isNotEmpty,
                  builder: (context, hasHeroImage) {
                    return RoleplayPageHeader(
                      useLightContent: hasHeroImage,
                    );
                  },
                ),
                RoleplayContent(),
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
