part of '../../../onboard_branching.dart';

/// Local data source for Onboard Branching
///
/// Handles caching of Onboarding Scenario Branching data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class OnboardBranchingLocalDataSource {
  /// Get all cached onboarding_scenario_branchings
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<OnboardingScenarioBranchingModel>> getCachedOnboardingScenarioBranchings();

  /// Cache multiple onboarding_scenario_branchings
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheOnboardingScenarioBranchings(List<OnboardingScenarioBranchingModel> models);

  /// Get cached onboarding_scenario_branching by id
  Future<OnboardingScenarioBranchingModel?> getCachedOnboardingScenarioBranching(String id);

  /// Cache single onboarding_scenario_branching
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheOnboardingScenarioBranching(String id, OnboardingScenarioBranchingModel model);

  /// Delete cached onboarding_scenario_branching
  Future<void> deleteCachedOnboardingScenarioBranching(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: OnboardBranchingLocalDataSource)
class OnboardBranchingLocalDataSourceImpl implements OnboardBranchingLocalDataSource {
  static const String _cacheKey = 'onboard_branching_cache';
  static const String _cacheListKey = 'onboard_branching_list_cache';

  final ILocalStoreService _localStoreService;

  OnboardBranchingLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OnboardingScenarioBranchingModel>> getCachedOnboardingScenarioBranchings() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => OnboardingScenarioBranchingModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheOnboardingScenarioBranchings(List<OnboardingScenarioBranchingModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _cacheListKey,
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<OnboardingScenarioBranchingModel?> getCachedOnboardingScenarioBranching(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return OnboardingScenarioBranchingModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOnboardingScenarioBranching(String id, OnboardingScenarioBranchingModel model) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedOnboardingScenarioBranching(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      // Note: Individual item caches (_cacheKey_id) are kept for specific item lookups
      // To clear everything, you could track all keys or implement prefix-based deletion
    } catch (e) {
      // Handle error silently or log
    }
  }
}
