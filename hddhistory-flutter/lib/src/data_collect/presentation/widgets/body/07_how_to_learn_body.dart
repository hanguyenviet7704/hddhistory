part of '../../../data_collect.dart';

class HowToLearnBody extends StatelessWidget {
  const HowToLearnBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              note: context.l10n.onboarding.onboardingHowToLearnNote,
              title: context.l10n.onboarding.onboardingHowToLearnTitle,
            ),

            20.verticalSpace,

            // Banner carousel reusing paywall decor logic
            PaywallBannerCarousel(
              onIndexChanged: (_) => AppService.instance.appTrackingService.trackObdHowToLearnSwipe(),
            ),
          ],
        );
      },
    );
  }
}
