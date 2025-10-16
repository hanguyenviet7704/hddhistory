part of '../../../data_collect.dart';

class ThisDescribeYouBody extends StatelessWidget {
  const ThisDescribeYouBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              "Does this seem like you?",
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20.h),

            // Questions
            ThisDescribeYouOptions(),
          ],
        );
      },
    );
  }
}

class ThisDescribeYouOptions extends StatelessWidget {
  const ThisDescribeYouOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, List<bool>>(
      selector: (state) => state.selectedThisDescribeYouOptions,
      builder: (context, selectedOptions) {
        final cubit = context.read<DataCollectCubit>();

        // Initialize options if empty
        if (selectedOptions.isEmpty) {
          // Initialize with 6 questions (3 yes/no pairs)
          for (int i = 0; i < 6; i++) {
            cubit.selectThisDescribeYouOption(i, false);
          }
        }

        final questions = [
          "I frequently use filler words like 'um' and 'uh' in my speech",
          "I find it difficult to express my thoughts and feelings to others",
          "I avoid making eye contact when I speak",
        ];

        return Flexible(
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final yesIndex = index * 2;
              final noIndex = index * 2 + 1;

              final isSelectedYes = yesIndex < selectedOptions.length ? selectedOptions[yesIndex] : false;
              final isSelectedNo = noIndex < selectedOptions.length ? selectedOptions[noIndex] : false;

              return ThisDescribeYouOption(
                title: question,
                isSelectedYes: isSelectedYes,
                isSelectedNo: isSelectedNo,
                onYesChanged: (value) {
                  // If yes is selected, ensure no is unselected
                  if (value) {
                    cubit.selectThisDescribeYouOption(noIndex, false);
                  }
                  cubit.selectThisDescribeYouOption(yesIndex, value);
                },
                onNoChanged: (value) {
                  // If no is selected, ensure yes is unselected
                  if (value) {
                    cubit.selectThisDescribeYouOption(yesIndex, false);
                  }
                  cubit.selectThisDescribeYouOption(noIndex, value);
                },
              );
            },
          ),
        );
      },
    );
  }
}
