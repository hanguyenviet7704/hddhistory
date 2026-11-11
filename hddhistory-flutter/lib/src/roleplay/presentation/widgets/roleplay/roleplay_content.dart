part of '../../../roleplay.dart';

class RoleplayContent extends StatelessWidget {
  const RoleplayContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.op(0.24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
                        child: const RoleplayContentList(),
                      ),
                    ),
                    BlocBuilder<RoleplayCubit, RoleplayState>(
                      buildWhen: (previous, current) =>
                          previous.isCurrentSectionRevealed != current.isCurrentSectionRevealed ||
                          previous.currentLesson.progess != current.currentLesson.progess ||
                          previous.isSendingFeedback != current.isSendingFeedback,
                      builder: (context, state) {
                        final isCompleted = state.isCurrentSectionRevealed;
                        final bool isLessonCompleted = state.currentLesson.progess == ProcessEnum.done;
                        final String label = isLessonCompleted ? context.l10n.roleplay.rolePlayShowResultButton : context.l10n.roleplay.rolePlayCompleteButton;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: isCompleted
                              ? RoleplayCompleteBottomCTA(
                                  key: const ValueKey('roleplay-complete-cta'),
                                  label: label,
                                  isLoading: state.isSendingFeedback,
                                  onPressed: () {
                                    final trackingData = RoleplayTrackingData.fromContext();
                                    if (trackingData != null) {
                                      AppService.instance.appTrackingService.trackRoleplayCompleteClick(trackingData);
                                    }
                                    context.read<RoleplayCubit>().endRoleplay();
                                  },
                                  bottomPadding: MediaQuery.paddingOf(context).bottom,
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
