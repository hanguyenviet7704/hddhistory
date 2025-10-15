part of '../../onboard.dart';

class OnboardContent {
  final String chatMessage;
  final String title;
  final String subtitle;
  final String description;
  final String iconPath;

  OnboardContent({
    required this.chatMessage,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconPath,
  });
}

@injectable
class IntroCubit extends Cubit<IntroState> {
  IntroCubit() : super(IntroState.initial());

  final List<OnboardContent> _onboardContents = [
    OnboardContent(
      chatMessage: "Don't let poor communication hold you back anymore.",
      title: "Missed chances",
      subtitle: "Unspoken ideas",
      description: "Limited growth",
      iconPath: AppAsset.images.common.birdThink.path,
    ),
    OnboardContent(
      chatMessage: "MeUp offers a structured approach to mastering your voice...",
      title: "No one is born a great communicator.",
      subtitle: "It's a skill you can build.",
      description: "",
      iconPath: AppAsset.images.common.birdSearch.path,
    ),
    OnboardContent(
      chatMessage: "You’ll be practicing with our exclusive MeUp Learning Loop method.",
      title: "Learn faster",
      subtitle: "Build habits quickly",
      description: "Make noticeable progress in a short time.",
      iconPath: AppAsset.images.common.birdHappy.path,
    ),
  ];

  List<OnboardContent> get onboardContents => _onboardContents;

  void setPage(int page) {
    if (page >= 0 && page < _onboardContents.length) {
      emit(state.copyWith(currentPage: page));
    }
  }
}
