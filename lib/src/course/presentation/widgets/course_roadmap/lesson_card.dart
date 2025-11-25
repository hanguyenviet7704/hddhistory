part of '../../../course.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final LessonEntity lessonRolePlay;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.lessonRolePlay,
  });

  Color get _backgroundColor {
    switch (lesson.progess) {
      case ProcessEnum.done:
        return AppCustomColor.backgroundWhite;
      case ProcessEnum.inProgress:
        return AppCustomColor.backgroundBrand;
      case ProcessEnum.notStarted:
        return AppCustomColor.backgroundGray;
    }
  }

  Color get _textColor {
    switch (lesson.progess) {
      case ProcessEnum.done:
        return AppCustomColor.textPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.brandPrimary300;
      case ProcessEnum.notStarted:
        return AppCustomColor.textQuaternary;
    }
  }

  Color? get _borderColor {
    if (lesson.progess == ProcessEnum.done) {
      return AppCustomColor.borderDefault;
    }
    return null;
  }

  bool get _showInProgressBadge => lesson.progess == ProcessEnum.inProgress;

  void _onTap(BuildContext context) {
    if (lesson.progess == ProcessEnum.notStarted) return;

    switch (lesson.type) {
      case LessonType.lesson:
        context.read<ProgressCubit>().loadUserProgressLesson(lessonId: lessonRolePlay.id);
        context.read<CourseLessonCubit>()
          ..reset()
          ..loadLesson(lesson.id);
        LessonListRoute().go(context);
        break;

      case LessonType.roleplay:
        if (lesson.progess == ProcessEnum.done && !kDebugMode) return;
        
        AppDI.injector.get<RoleplayCubit>()
          ..reset()
          ..setLessonId(lesson)
          ..loadLearningItem(lesson.learningItemId, estimateCompleTime: lesson.estimateCompleTime);
        RoleplayIntroRoute().go(context);
        break;

      case LessonType.output:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            constraints: BoxConstraints(minHeight: 44.h),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12.r),
              border: _borderColor != null ? Border.all(color: _borderColor!, width: 1) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson title
                AppText(
                  lesson.title.text,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                8.verticalSpace,
                // Lesson metadata row
                Row(
                  children: [
                    // Lesson type
                    LessonMetadata(
                      icon: lesson.icon,
                      text: lesson.icon.title.text,
                      textColor: _textColor,
                    ),
                    20.horizontalSpace,
                    // Duration
                    if (lesson.estimateCompleTime.en.isNotEmpty) ...[
                      SvgPicture.asset(
                        AppAsset.svg.app.icClock,
                        colorFilter: ColorFilter.mode(_textColor, BlendMode.srcIn),
                        width: 16.w,
                      ),
                      8.horizontalSpace,
                      LessonMetadata(
                        text: lesson.estimateCompleTime.text,
                        textColor: _textColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // In Progress badge
          if (_showInProgressBadge)
            Positioned(
              top: -10.h,
              left: 16.w,
              child: const InProgressBadge(),
            ),
        ],
      ),
    );
  }
}
