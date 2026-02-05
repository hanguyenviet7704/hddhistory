part of '../../../data_collect.dart';

class NameCollectBody extends StatelessWidget {
  const NameCollectBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          context.text.onboarding.onboardingUserNameQuestion,
          textAlign: TextAlign.center,
          maxLines: 3,
          enableFitScaleDown: true,
          style: AppStyle.textBold20.copyWith(
            color: const Color(0xFF364152), // Text/Secondary
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        20.verticalSpace,
        OnboardingInput(
          hintText: context.text.onboarding.onboardingUserNamePlaceholder,
          controller: context.read<DataCollectCubit>().nameController,
          onChanged: (value) => context.read<DataCollectCubit>().updateUserName(value),
          onTap: () => AppService.instance.appTrackingService.trackObdNameClick(),
        ),
        Spacer(),
      ],
    );
  }
}
