part of '../../lesson.dart';

class LessonTimelineBuilder {
  const LessonTimelineBuilder();

  Widget buildLessonListView({
    required LessonState state,
    required Widget activeBody,
    required LessonPageController controller,
    required Widget Function(QuestionEntity question) buildReviewBody,
    required VoidCallback onTrackCurrentLearningItemScroll,
  }) {
    final items = collectLessonItems(
      state: state,
      activeBody: activeBody,
      buildReviewBody: buildReviewBody,
    );

    if (items.isEmpty) {
      controller.handleEmptyItems();
      return const SizedBox.shrink();
    }

    controller.handleAutoScroll(
      itemCount: items.length,
      shouldSuppressAutoScroll: state.suppressNextAutoScroll,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final listHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) => controller.handleUserScroll(notification, onTrackCurrentLearningItemScroll),
          child: ListView.separated(
            controller: controller.scrollController,
            itemCount: items.length,
            padding: EdgeInsets.only(bottom: 160.h),
            separatorBuilder: (context, index) => 40.verticalSpace,
            itemBuilder: (context, index) {
              if (index == items.length - 1) {
                return KeyedSubtree(
                  key: controller.lastItemKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: listHeight),
                    child: items[index],
                  ),
                );
              }

              return items[index];
            },
          ),
        );
      },
    );
  }

  List<Widget> collectLessonItems({
    required LessonState state,
    required Widget activeBody,
    required Widget Function(QuestionEntity question) buildReviewBody,
  }) {
    final items = <Widget>[];

    if (state.pageData.items.isEmpty) return items;

    final lastItemIndex = math.min(state.currentLearningItemIndex, state.pageData.items.length - 1);
    if (lastItemIndex < 0) return items;

    for (int itemIndex = 0; itemIndex <= lastItemIndex; itemIndex++) {
      final learningItem = state.pageData.items[itemIndex];
      final isCurrentItem = itemIndex == state.currentLearningItemIndex;

      switch (learningItem.type) {
        case LearningItemType.theory:
          final documents = learningItem.documents;
          if (documents.isEmpty) continue;

          final activeDocIndex = isCurrentItem ? math.min(state.currentLessonIndex, documents.length - 1) : documents.length - 1;

          for (int docIndex = 0; docIndex <= activeDocIndex; docIndex++) {
            if (isCurrentItem && docIndex == activeDocIndex) {
              items.add(activeBody);
              continue;
            }

            items.add(DocumentWidget(documents: documents[docIndex].document));
          }

        case LearningItemType.exercise || LearningItemType.roleplay:
          final questions = learningItem.questions;
          if (questions.isEmpty) continue;

          final activeQuestionIndex = isCurrentItem ? math.min(state.currentLessonIndex, questions.length - 1) : questions.length - 1;

          for (int questionIndex = 0; questionIndex <= activeQuestionIndex; questionIndex++) {
            if (isCurrentItem && questionIndex == activeQuestionIndex) {
              items.add(activeBody);
              continue;
            }

            items.add(buildReviewBody(questions[questionIndex]));
          }
      }
    }

    return items;
  }
}
