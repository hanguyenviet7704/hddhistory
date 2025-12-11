part of '../../data_collect.dart';

/// Shows a single motivation slide. The caller pushes this route with the
/// desired [step] so we don't reveal all slides at once.
class DataCollectMotivationStepPage extends StatelessWidget {
  const DataCollectMotivationStepPage({super.key, required this.step});

  /// 0: welcome, 1: motivationOne, 2: motivationTwo, 3: motivationThree
  final int step;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        final slide = _buildSlide(context, state);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: slide.isDark ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(context),
            child: Scaffold(
              backgroundColor: slide.backgroundColor,
              body: SafeArea(
                child: MotivationStepContent(
                  imageUrl: slide.imageUrl,
                  title: slide.title,
                  subtitle: slide.subtitle,
                  isDarkBackground: slide.isDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    DataCollectRoute().go(context);
  }

  _MotivationSlide _buildSlide(BuildContext context, DataCollectState state) {
    final userName = state.userName ?? context.read<DataCollectCubit>().nameController.text;
    final motivation = _pickMotivation(state.onboardData);
    final includeUserName = step != 3; // Step 3 should not display user name

    final processed = _applyUserName(motivation.content.text, userName, includeUserName: includeUserName);
    final parts = processed.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final title = parts.isNotEmpty ? parts.first.trim() : processed.trim();
    final subtitle = parts.length > 1 ? parts.skip(1).join('\n').trim() : '';

    final bool isDark = step == 0;
    final Color background = isDark ? AppCustomColor.textBrand : AppCustomColor.brandPrimary50;

    return _MotivationSlide(
      title: title,
      subtitle: subtitle,
      imageUrl: motivation.image.isNotEmpty ? motivation.image : AppAsset.images.common.birdWing.path,
      backgroundColor: background,
      isDark: isDark,
    );
  }

  OnboardMotivationEntity _pickMotivation(OnboardEntity onboard) {
    switch (step) {
      case 0:
        return onboard.welcome;
      case 1:
        return onboard.motivationOne;
      case 2:
        return onboard.motivationTwo;
      case 3:
      default:
        return onboard.motivationThree;
    }
  }

  String _applyUserName(String text, String? userName, {required bool includeUserName}) {
    final placeholders = [r'\user_name\', '{user_name}', '{userName}', '<user_name>'];

    if (!includeUserName || userName == null || userName.isEmpty) {
      var result = text;
      for (final placeholder in placeholders) {
        result = result.replaceAll(placeholder, '').trim();
      }
      return result.trim();
    }

    var result = text;
    for (final placeholder in placeholders) {
      result = result.replaceAll(placeholder, userName);
    }
    return result;
  }
}

class _MotivationSlide {
  final String title;
  final String subtitle;
  final String imageUrl;
  final Color backgroundColor;
  final bool isDark;

  _MotivationSlide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.backgroundColor,
    required this.isDark,
  });
}
