part of '../../../data_collect.dart';

class AnalysisState extends StatelessWidget {
  const AnalysisState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC7C5FA), // Border/Brand
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DCachedImage(
                      url: AppAsset.images.common.birdStand.path,
                      width: 128.w,
                      fit: BoxFit.contain,
                    ),

                    32.verticalSpace,

                    AppText(
                      context.text.onboarding.onboardingLoadingPersonalizationText,
                      maxLines: 20,
                      textAlign: TextAlign.center,
                      style: AppStyle.textBold20.copyWith(
                        color: const Color(0xFF362F82), // Brand/Brand/Primary/700
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
