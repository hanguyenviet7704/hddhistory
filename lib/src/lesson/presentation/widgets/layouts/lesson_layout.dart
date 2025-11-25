part of '../../../lesson.dart';

class LessonLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  const LessonLayout({
    super.key,
    required this.body,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocSelector<LessonCubit, LessonState, double>(
              selector: (state) => state.progress,
              builder: (context, progress) {
                return LessonProgressBar();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    12.verticalSpace,
                    LessonBadge(),
                    ChatInformationWidget(),
                    body,
                    80.verticalSpace,
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
