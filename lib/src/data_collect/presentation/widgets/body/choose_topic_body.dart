part of '../../../data_collect.dart';

class ChooseTopicBody extends StatelessWidget {
  const ChooseTopicBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            AppText(
              "Choose the topics\nyou want to master",
              textAlign: TextAlign.center,
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
            ),

            SizedBox(height: 4.h),

            // Subtitle
            AppText(
              "The choice won't limit your learning experience",
              maxLines: 10,
              style: AppStyle.text12.copyWith(
                color: const Color(0xFF7F8EA4), // Text/Tertiary
              ),
            ),

            SizedBox(height: 20.h),

            // Topic Options
            TopicOptions(),
          ],
        );
      },
    );
  }
}

class TopicOptions extends StatelessWidget {
  const TopicOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, List<String>>(
      selector: (state) => state.selectedTopics,
      builder: (context, selectedTopics) {
        final cubit = context.read<DataCollectCubit>();

        final topics = [
          'Verbal Communication',
          'Public speaking',
          'Active Listening',
          'Nonverbal Communication',
          'Emotional Intelligence',
          'Conflict Resolution',
          'Presentation Skills',
          'Language',
          'Others',
        ];

        return Expanded(
          child: ListView.separated(
            itemCount: topics.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final isSelected = selectedTopics.contains(topic);

              return TopicOption(
                title: topic,
                isSelected: isSelected,
                onChanged: (isSelected) {
                  cubit.toggleTopic(topic);
                },
              );
            },
          ),
        );
      },
    );
  }
}
