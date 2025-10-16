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
              "What do you usually struggle with when speaking?",
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
              "Select all the options that match your situation",
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            SizedBox(height: 20.h),

            // Struggle Options
            Expanded(
              child: StruggleOptions(),
            ),
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
    return BlocSelector<DataCollectCubit, DataCollectState, List<String>>(
      selector: (state) => state.selectedStruggles,
      builder: (context, selectedStruggles) {
        final cubit = context.read<DataCollectCubit>();

        final struggles = [
          "Confidence in Speaking",
          "Audience Engagement",
          "Clear Idea Organization",
          "Using voice effectively",
          "Q&A and Feedback Handling",
          "Nervousness Control",
        ];

        return ListView.builder(
          itemCount: struggles.length,
          itemBuilder: (context, index) {
            final struggle = struggles[index];
            final isSelected = selectedStruggles.contains(struggle);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: StruggleOption(
                title: struggle,
                isSelected: isSelected,
                onChanged: (value) {
                  cubit.toggleStruggle(struggle);
                },
              ),
            );
          },
        );
      },
    );
  }
}
