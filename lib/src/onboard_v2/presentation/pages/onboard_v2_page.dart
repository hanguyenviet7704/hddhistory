part of '../../onboard_v2.dart';

class OnboardV2Page extends StatefulWidget {
  const OnboardV2Page({super.key});

  @override
  State<OnboardV2Page> createState() => _OnboardV2PageState();
}

class _OnboardV2PageState extends State<OnboardV2Page> {
  OnboardV2PageStep? _lastTrackedPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _trackPage(context.read<OnboardV2Cubit>().state.currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardV2Cubit, OnboardV2State>(
      listenWhen: (previous, current) => previous.currentPage != current.currentPage,
      listener: (_, state) => _trackPage(state.currentPage),
      builder: (context, state) {
        return switch (state.currentPage) {
          OnboardV2PageStep.p1Intro => const OnboardV2IntroPage(),
          OnboardV2PageStep.p2Name => const OnboardV2NamePage(),
          OnboardV2PageStep.p3Age => const OnboardV2AgePage(),
          OnboardV2PageStep.p4Skillset => const OnboardV2SkillsetChoicePage(),
          OnboardV2PageStep.p5Demo => const OnboardV2SkillsetDemoPage(),
          OnboardV2PageStep.p6Notification => const OnboardV2NotificationPage(),
          OnboardV2PageStep.p7Recommendation => const OnboardV2RecommendationPage(),
        };
      },
    );
  }

  void _trackPage(OnboardV2PageStep page) {
    if (_lastTrackedPage == page) return;
    _lastTrackedPage = page;
    OnboardV2Tracking.trackPageView(page);
  }
}
