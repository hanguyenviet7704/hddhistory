part of '../../../../exercise.dart';

class TheoryBadge extends StatelessWidget {
  const TheoryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocSelector<TheoryCubit, TheoryState, TagEntity>(
        selector: (state) => state.currentDocument.tag,
        builder: (context, tag) {
          return Row(
            spacing: 6.w,
            children: [
              DCachedImage(
                url: tag.icon,
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
