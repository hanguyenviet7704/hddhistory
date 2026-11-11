part of '../../home.dart';

class CategoryFilterRequest implements JsonRequestConvertible {
  const CategoryFilterRequest({
    this.onboardingIntroduces = const [],
    this.isAll,
  });

  factory CategoryFilterRequest.forOnboarding({
    List<CategoryOnboardingIntroduce>? values,
    bool isAll = true,
  }) {
    return CategoryFilterRequest(
      onboardingIntroduces: values ?? CategoryOnboardingIntroduce.values,
      isAll: isAll,
    );
  }

  final List<CategoryOnboardingIntroduce> onboardingIntroduces;
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
class GetAllCategoriesUseCase implements BaseUseCase<PageBreakRequest<CategoryFilterRequest>, BasePageBreak<CategoryEntity>> {
  final IHomeRepository _repository;

  GetAllCategoriesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<CategoryEntity>> call(PageBreakRequest<CategoryFilterRequest> params) {
    return _repository.getAllCategories(params);
  }
}
