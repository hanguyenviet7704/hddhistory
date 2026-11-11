part of '../../onboarding.dart';

/// One branch of the onboarding v3 taxonomy — e.g. "Speaking", "Listening".
/// Fetched from `GET /api/v1/onboarding-taxonomy` alongside its packages.
@freezed
abstract class OnboardingBranchEntity with _$OnboardingBranchEntity {
  const factory OnboardingBranchEntity({
    @Default('') String code,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default('') String iconUrl,
    @Default('') String imageUrl,
    @Default(0) int order,
    @Default(true) bool isSelectable,
    String? categoryId,
    @Default(true) bool isActive,
  }) = _OnboardingBranchEntity;
}

/// A problem/desire package nested under a branch by [branchCode].
@freezed
abstract class OnboardingPackageEntity with _$OnboardingPackageEntity {
  const factory OnboardingPackageEntity({
    @Default('') String code,
    @Default('') String branchCode,
    @Default(BaseMultiLanguage()) BaseMultiLanguage problemLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage desireLabel,
    @Default(0) int order,
    @Default(true) bool isActive,
  }) = _OnboardingPackageEntity;
}

@freezed
abstract class OnboardingTaxonomyEntity with _$OnboardingTaxonomyEntity {
  const factory OnboardingTaxonomyEntity({
    @Default([]) List<OnboardingBranchEntity> branches,
    @Default([]) List<OnboardingPackageEntity> packages,
  }) = _OnboardingTaxonomyEntity;
}

extension OnboardingTaxonomyEntityX on OnboardingTaxonomyEntity {
  bool get isEmpty => branches.isEmpty || packages.isEmpty;

  List<OnboardingBranchEntity> get selectableBranches =>
      [...branches.where((b) => b.isSelectable && b.isActive)]..sort((a, b) => a.order.compareTo(b.order));

  List<OnboardingPackageEntity> packagesOf(String branchCode) =>
      [...packages.where((p) => p.branchCode == branchCode && p.isActive)]..sort((a, b) => a.order.compareTo(b.order));

  OnboardingPackageEntity? packageByCode(String code) =>
      packages.cast<OnboardingPackageEntity?>().firstWhere((p) => p!.code == code, orElse: () => null);

  OnboardingBranchEntity? branchByCode(String code) =>
      branches.cast<OnboardingBranchEntity?>().firstWhere((b) => b!.code == code, orElse: () => null);
}
