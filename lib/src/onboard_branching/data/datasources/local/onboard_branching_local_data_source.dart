part of '../../../onboard_branching.dart';

/// Local data source for Onboard Branching
///
/// Handles caching of Onboarding Scenario Branching data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class OnboardBranchingLocalDataSource {
  Future<OnboardingScenarioBranchingModel?> getCachedOnboardingScenarioBranching();

  Future<void> cacheOnboardingScenarioBranching(OnboardingScenarioBranchingModel model);

  Future<void> deleteCachedOnboardingScenarioBranching();

  Future<void> clearCache();
}

@LazySingleton(as: OnboardBranchingLocalDataSource)
class OnboardBranchingLocalDataSourceImpl implements OnboardBranchingLocalDataSource {
  static const String _cacheKey = 'onboard_branching_cache';
  static const String _cacheListKey = 'onboard_branching_list_cache';

  final ILocalStoreService _localStoreService;

  OnboardBranchingLocalDataSourceImpl(this._localStoreService);

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
  Future<OnboardingScenarioBranchingModel?> getCachedOnboardingScenarioBranching() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheKey);
      if (data.isEmpty) return null;

      return OnboardingScenarioBranchingModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOnboardingScenarioBranching(OnboardingScenarioBranchingModel model) async {
    try {
      await _localStoreService.setMap(
        key: _cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedOnboardingScenarioBranching() async {
    try {
      await _localStoreService.remove(key: _cacheKey);
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
