part of '../../../course.dart';

class LessonExplainPopup {
  static Future<void> show(BuildContext context, {String? explain}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp))),
      routeSettings: const RouteSettings(name: RouteNamed.lessonExplainPopup),
      builder: (context) => const _LessonExplainBottomSheet(),
    );
  }
}

class _LessonExplainBottomSheet extends StatelessWidget {
  const _LessonExplainBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top handle bar
          8.verticalSpace,
          Container(
            width: 50.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: AppCustomColor.textBrand.op(0.6),
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          20.verticalSpace,

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                AppText(
                  'How Your Practice Works',
                  style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                ),

                // Subtitle
                AppText(
                  'Based on your Roleplay, MeUp rated your skills in <strong>three levels</strong>',
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                    height: 1.75,
                  ),
                  maxLines: 10,
                ),
                24.verticalSpace,

                // Section 1: Required to complete
                _PracticeSectionCard(
                  badge: _ExplainBadge(
                    iconPath: AppAsset.svg.app.icCheckVerify,
                    text: 'Required to complete',
                    backgroundColor: AppCustomColor.successGreen,
                  ),
                  items: const [
                    _PracticeLevelItem(
                      level: StrengthLevel.weakPoint,
                      title: 'Weakpoint',
                      description: 'Needs major improvement',
                    ),
                    _PracticeLevelItem(
                      level: StrengthLevel.morePractice,
                      title: 'More Practice',
                      description: 'Needs more training',
                    ),
                  ],
                ),
                12.verticalSpace,

                // Section 2: May skip to save time
                _PracticeSectionCard(
                  badge: _ExplainBadge(
                    iconPath: AppAsset.svg.app.icChevronRightDouble,
                    text: 'May skip to save time',
                    backgroundColor: AppCustomColor.textQuaternary,
                  ),
                  items: const [
                    _PracticeLevelItem(
                      level: StrengthLevel.optionalPractice,
                      title: 'Optional Practice',
                      description: 'Already strong',
                    ),
                  ],
                ),
                100.verticalSpace,

                // Footer text
                Center(
                  child: AppText(
                    'Keep going to build your all-round skills!',
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textQuaternary,
                      height: 1.75,
                    ),
                  ),
                ),
                24.verticalSpace,

                // Done button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 54.h,
                    decoration: BoxDecoration(
                      color: AppCustomColor.brandPrimary,
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    child: Center(
                      child: AppText(
                        'Done',
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                30.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainBadge extends StatelessWidget {
  final String iconPath;
  final String text;
  final Color backgroundColor;

  const _ExplainBadge({
    required this.iconPath,
    required this.text,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 16.w,
          ),
          4.horizontalSpace,
          AppText(
            text,
            style: AppStyle.text12.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeLevelItem extends StatelessWidget {
  final StrengthLevel level;
  final String title;
  final String description;

  const _PracticeLevelItem({
    required this.level,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Strength indicator icon
        StrengthIndicatorBadge(level: level),
        12.horizontalSpace,

        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              AppText(
                description,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textSecondary,
                  height: 1.75,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PracticeSectionCard extends StatelessWidget {
  final _ExplainBadge badge;
  final List<_PracticeLevelItem> items;

  const _PracticeSectionCard({
    required this.badge,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          badge,
          16.verticalSpace,

          // Practice level items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) 16.verticalSpace,
                item,
              ],
            );
          }),
        ],
      ),
    );
  }
}
