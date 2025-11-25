part of '../../../../lesson.dart';

class LessonBadge extends StatelessWidget {
  const LessonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocSelector<LessonCubit, LessonState, TagEntity>(
        selector: (state) => state.currentTag,
        builder: (context, tag) {
          if (tag.url.isEmpty) return const SizedBox.shrink();
          return Row(
            spacing: 6.w,
            children: [
              DCachedImage(
                url: tag.url,
                width: 20.w,
                height: 20.w,
              ),
              AppText(
                tag.title.text.toUpperCase(),
                style: AppStyle.textBold10.copyWith(
                  color: tag.color.toHexColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
