part of '../../course.dart';

class ChangeCoursePage extends StatefulWidget {
  const ChangeCoursePage({super.key});

  @override
  State<ChangeCoursePage> createState() => _ChangeCoursePageState();
}

class _ChangeCoursePageState extends State<ChangeCoursePage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('change-course-page'),
      backgroundColor: AppCustomColor.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppCustomColor.backgroundWhite,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: IconButton(
            onPressed: () => context.back(),
            constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.w),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppCustomColor.textPrimary,
              size: 20.w,
            ),
          ),
        ),
        title: AppText(
          context.l10n.allcourse.changeCourseTitle,
          style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          12.verticalSpace,
          BlocSelector<HomeCubit, HomeState, List<SkillsetEntity>>(
            selector: (s) => s.skillsets,
            builder: (context, skillsets) {
              final tabs = [
                context.l10n.allcourse.changeCourseTabAll,
                ...skillsets.map((s) => s.title.text),
              ];
              return FilterTabBar(
                tabs: tabs,
                selectedIndex: _selectedTabIndex,
                onTabSelected: (i) => setState(() => _selectedTabIndex = i),
              );
            },
          ),
          12.verticalSpace,
          Expanded(
            child: BlocSelector<HomeCubit, HomeState,
                ({HomeStatus status, List<CourseEntity> courses, List<SkillsetEntity> skillsets})>(
              selector: (s) => (
                status: s.status,
                courses: s.skillsets.expand((sk) => sk.coursesWithSkillset).toList(),
                skillsets: s.skillsets,
              ),
              builder: (context, snap) {
                if (snap.status == HomeStatus.initial || snap.status == HomeStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppCustomColor.brandPrimary),
                  );
                }

                final filtered = _selectedTabIndex == 0
                    ? snap.courses
                    : snap.courses
                        .where(
                          (c) => c.skillset.id == snap.skillsets[_selectedTabIndex - 1].id,
                        )
                        .toList();

                final currentCourseId = context.read<HomeCubit>().state.currentCourse.id;

                if (filtered.isEmpty) return const CourseEmptyState();

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => 8.verticalSpace,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return CourseListTile(
                      key: ValueKey(course.id),
                      course: course,
                      isSelected: course.id == currentCourseId,
                      onTap: () {
                        context.read<CourseRoadmapCubit>().setRoadmapSource('change_course');
                        context.read<HomeCubit>()
                          ..selectSkillset(course.skillset)
                          ..selectCourse(course);
                        context.back();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
