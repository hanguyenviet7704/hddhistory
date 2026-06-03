part of '../../../lesson.dart';

class LessonDualModeLayout extends StatelessWidget {
  const LessonDualModeLayout({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.readBody,
    required this.audioBody,
    required this.isLoading,
    this.bottom,
    this.trailing,
  });

  final LessonEntryMode selectedMode;
  final ValueChanged<LessonEntryMode> onModeSelected;
  final VoidCallback onClose;
  final Widget readBody;
  final Widget audioBody;
  final Widget? bottom;
  final Widget? trailing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LessonShellLayout(
      selectedMode: selectedMode,
      onModeSelected: onModeSelected,
      onClose: onClose,
      showModeToggle: true,
      readBody: readBody,
      audioBody: audioBody,
      bottom: bottom,
      trailing: trailing,
      isLoading: isLoading,
    );
  }
}
