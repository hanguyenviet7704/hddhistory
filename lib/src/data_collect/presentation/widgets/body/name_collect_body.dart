part of '../../../data_collect.dart';

class NameCollectBody extends StatelessWidget {
  const NameCollectBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Title
        AppText(
          context.text.onboardingUserNameQuestion,
          style: AppStyle.textBold20.copyWith(
            color: const Color(0xFF364152), // Text/Secondary
            fontWeight: FontWeight.w500,
          ),
        ),

        Spacer(),
        // Input Field
        OnboardingInput(
          hintText: context.text.onboardingUserNamePlaceholder,
          controller: context.read<DataCollectCubit>().nameController,
          onChanged: (value) => context.read<DataCollectCubit>().updateUserName(value),
        ),
        Spacer(),
      ],
    );
  }
}
