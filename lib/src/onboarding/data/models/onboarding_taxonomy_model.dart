part of '../../onboarding.dart';

@freezed
abstract class OnboardingBranchModel with _$OnboardingBranchModel {
  const factory OnboardingBranchModel({
    @Default('') String code,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default('') String iconUrl,
    @Default('') String imageUrl,
    @Default(0) int order,
    @Default(true) bool isSelectable,
    String? skillsetId,
    @Default(true) bool isActive,
  }) = _OnboardingBranchModel;

  factory OnboardingBranchModel.fromJson(Map<String, dynamic> json) => _$OnboardingBranchModelFromJson(json);
}

extension OnboardingBranchModelExtension on OnboardingBranchModel {
  // NOTE: `order` must be qualified with `this.` — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body (see
  // onboarding_paths_config_model.dart for the same gotcha).
  OnboardingBranchEntity toEntity() => OnboardingBranchEntity(
    code: code,
    label: label,
    subtitle: subtitle,
    iconUrl: iconUrl,
    imageUrl: imageUrl,
    order: this.order,
    isSelectable: isSelectable,
    skillsetId: skillsetId,
    isActive: isActive,
  );
}

@freezed
abstract class OnboardingPackageModel with _$OnboardingPackageModel {
  const factory OnboardingPackageModel({
    @Default('') String code,
    @Default('') String branchCode,
    @Default(BaseMultiLanguage()) BaseMultiLanguage problemLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage desireLabel,
    @Default(0) int order,
    @Default(true) bool isActive,
  }) = _OnboardingPackageModel;

  factory OnboardingPackageModel.fromJson(Map<String, dynamic> json) => _$OnboardingPackageModelFromJson(json);
}

extension OnboardingPackageModelExtension on OnboardingPackageModel {
  // See the `this.order` note above — same injectable top-level shadowing.
  OnboardingPackageEntity toEntity() => OnboardingPackageEntity(
    code: code,
    branchCode: branchCode,
    problemLabel: problemLabel,
    desireLabel: desireLabel,
    order: this.order,
    isActive: isActive,
  );
}

@freezed
abstract class OnboardingTaxonomyModel with _$OnboardingTaxonomyModel {
  const factory OnboardingTaxonomyModel({
    @Default([]) List<OnboardingBranchModel> branches,
    @Default([]) List<OnboardingPackageModel> packages,
  }) = _OnboardingTaxonomyModel;

  factory OnboardingTaxonomyModel.fromJson(Map<String, dynamic> json) => _$OnboardingTaxonomyModelFromJson(json);
}

extension OnboardingTaxonomyModelExtension on OnboardingTaxonomyModel {
  OnboardingTaxonomyEntity toEntity() => OnboardingTaxonomyEntity(
    branches: branches.map((b) => b.toEntity()).toList(),
    packages: packages.map((p) => p.toEntity()).toList(),
  );
}
