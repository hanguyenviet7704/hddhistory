part of '../../onboard_v2.dart';

class OnboardV2SkillsetSelection {
  const OnboardV2SkillsetSelection({
    required this.skillsets,
    required this.skillsetIds,
    required this.introduces,
  });

  final List<SkillsetEntity> skillsets;
  final List<String> skillsetIds;
  final List<SkillsetOnboardingIntroduce> introduces;
}

abstract final class OnboardV2SkillsetSelectionMapper {
  static OnboardV2SkillsetSelection mapSelected(List<SkillsetEntity> selectedSkillsets) {
    final seenIds = <String>{};
    final skillsets = <SkillsetEntity>[];

    for (final skillset in selectedSkillsets) {
      final id = skillset.id.trim();
      if (id.isEmpty || !seenIds.add(id)) continue;
      skillsets.add(skillset.copyWith(id: id));
    }

    final seenIntroduces = <SkillsetOnboardingIntroduce>{};
    final introduces = <SkillsetOnboardingIntroduce>[];
    for (final skillset in skillsets) {
      final introduce = skillset.onboardingIntroduce;
      if (introduce == null || !seenIntroduces.add(introduce)) continue;
      introduces.add(introduce);
    }

    return OnboardV2SkillsetSelection(
      skillsets: skillsets,
      skillsetIds: skillsets.map((skillset) => skillset.id).toList(),
      introduces: introduces,
    );
  }
}
