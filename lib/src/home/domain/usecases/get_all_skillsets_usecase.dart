part of '../../home.dart';

class SkillsetFilterRequest implements JsonRequestConvertible {
  const SkillsetFilterRequest({
    this.onboardingIntroduces = const [],
    this.isAll,
  });

  factory SkillsetFilterRequest.forOnboarding({
    List<SkillsetOnboardingIntroduce>? values,
    bool isAll = true,
  }) {
    return SkillsetFilterRequest(
      onboardingIntroduces: values ?? SkillsetOnboardingIntroduce.values,
      isAll: isAll,
    );
  }

  final List<SkillsetOnboardingIntroduce> onboardingIntroduces;
  final bool? isAll;

  bool get hasFilters => onboardingIntroduces.isNotEmpty || isAll != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      if (onboardingIntroduces.isNotEmpty) 'onboardingIntroduces': ListParam<String>(onboardingIntroduces.map((introduce) => introduce.name).toList(), ListFormat.multi),
      if (isAll != null) 'isAll': isAll,
    };
  }
}

@lazySingleton
class GetAllSkillsetsUseCase implements BaseUseCase<PageBreakRequest<SkillsetFilterRequest>, BasePageBreak<SkillsetEntity>> {
  final IHomeRepository _repository;

  GetAllSkillsetsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> call(PageBreakRequest<SkillsetFilterRequest> params) {
    return _repository.getAllSkillsets(params);
  }
}
