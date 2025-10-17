part of '../../../data_collect.dart';

class StruggleWhenSpeakingBody extends StatelessWidget {
  const StruggleWhenSpeakingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              context.text.onboardingStruggleQuestion,
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            4.verticalSpace,

            // Subtitle
            AppText(
              context.text.onboardingStruggleQuestionSubtitle,
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            SizedBox(height: 20.h),

            // Struggle Options
            StruggleOptions(),
          ],
        );
      },
    );
  }
}

class StruggleOptions extends StatelessWidget {
  const StruggleOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: BlocBuilder<DataCollectCubit, DataCollectState>(
        buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedStruggles != current.selectedStruggles,
        builder: (context, state) {
          final cubit = context.read<DataCollectCubit>();
          return ListView.separated(
            itemCount: state.onboardData.strugglesWhenSpeaking.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final struggle = state.onboardData.strugglesWhenSpeaking[index];
              final isSelected = state.isStruggleSelected(struggle);

              return StruggleOption(
                value: struggle,
                isSelected: isSelected,
                onChanged: (value) => cubit.selectStruggle(value ?? OnboardOptionEntity()),
              );
            },
          );
        },
      ),
    );
  }
}
