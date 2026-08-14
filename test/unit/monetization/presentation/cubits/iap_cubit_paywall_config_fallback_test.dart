import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Covers IapCubit.resolvedPaywallConfig / prefetchPaywallConfig — the part
/// of the resolution chain (API -> local cache -> Remote Config -> bundled
/// defaults) that lives above the repository. The API -> cache half is
/// covered by monetization_repository_paywall_config_test.dart.
void main() {
  group('IapCubit paywall config resolution chain', () {
    late _FakeMonetizationRepository repository;
    late _FakeRemoteConfigService remoteConfig;
    late IapCubit cubit;

    setUp(() {
      repository = _FakeMonetizationRepository();
      remoteConfig = _FakeRemoteConfigService(_config(lessonLock: 5));
      cubit = _newCubit(repository, remoteConfig);
    });

    test('Given no prefetch has resolved yet, When read, Then it falls back to Remote Config so a cold start with no network still renders', () {
      expect(cubit.resolvedPaywallConfig, remoteConfig.config);
    });

    test('Given the API prefetch succeeds, When read, Then it serves the API value instead of Remote Config', () async {
      repository.nextConfig = _config(lessonLock: 9);

      await cubit.prefetchPaywallConfig();

      expect(cubit.resolvedPaywallConfig.lessonLock, 9);
      expect(cubit.resolvedPaywallConfig, isNot(remoteConfig.config));
    });

    test('Given the very first prefetch fails, When read, Then it keeps deferring to Remote Config rather than going blank', () async {
      repository.shouldFail = true;

      await cubit.prefetchPaywallConfig();

      expect(cubit.resolvedPaywallConfig, remoteConfig.config);
    });

    test('Given a prior successful prefetch, When a later refresh fails, Then it keeps the last good value instead of clearing it', () async {
      repository.nextConfig = _config(lessonLock: 9);
      await cubit.prefetchPaywallConfig();
      expect(cubit.resolvedPaywallConfig.lessonLock, 9);

      repository.shouldFail = true;
      await cubit.prefetchPaywallConfig();

      expect(cubit.resolvedPaywallConfig.lessonLock, 9, reason: 'a failed background refresh must not wipe a good in-memory value');
    });

    test('Given two concurrent prefetch calls, When awaited, Then they share a single in-flight API fetch', () async {
      repository.delay = const Duration(milliseconds: 20);
      repository.nextConfig = _config(lessonLock: 9);

      await Future.wait([cubit.prefetchPaywallConfig(), cubit.prefetchPaywallConfig()]);

      expect(repository.getPaywallConfigCalls, 1);
    });

    test('Given a slow paywall config refresh, When the paywall opens, Then loadIapProducts never waits on it', () async {
      repository.delay = const Duration(milliseconds: 800);
      repository.products = const [IapProductEntity(id: 'row-annual', productId: 'annual')];
      remoteConfig.config = _configWithProducts(['annual']);

      final stopwatch = Stopwatch()..start();
      final isReady = await cubit.loadIapProducts();
      stopwatch.stop();

      expect(isReady, isTrue);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 300)));
    });
  });
}

IapCubit _newCubit(_FakeMonetizationRepository repository, _FakeRemoteConfigService remoteConfig) {
  return IapCubit(
    repository,
    _FakeIapService(),
    _FakeTrackingService(),
    GetPackagesUsecase(repository),
    PurchaseUsecase(repository),
    RestoreUsecase(repository),
    VerifyUsecase(repository),
    const ResolvePaywallStrategyUsecase(),
    ValidateVoucherUsecase(repository),
    remoteConfig,
    GetPaywallConfigUsecase(repository),
    GetPaywallLogicSaleUsecase(repository),
    _FakePackageInfoService(),
  );
}

PaywallConfigEntity _config({required int lessonLock}) {
  return PaywallConfigEntity(schemaVersion: 2, lessonLock: lessonLock);
}

PaywallConfigEntity _configWithProducts(List<String> productIds) {
  return PaywallConfigEntity(
    schemaVersion: 2,
    saleStrategy: PaywallSaleStrategyEntity(
      defaultUser: PaywallDefaultUserStrategyEntity(
        products: [for (final id in productIds) PaywallProductReferenceEntity(appleProductId: id, googleProductId: id)],
      ),
    ),
  );
}

class _FakeMonetizationRepository implements IMonetizationRepository {
  List<IapProductEntity> products = const [];
  int getProductsCalls = 0;

  PaywallConfigEntity? nextConfig;
  bool shouldFail = false;
  Duration? delay;
  int getPaywallConfigCalls = 0;

  @override
  Stream<PurchaseDetails> get purchaseDetailStream => const Stream.empty();

  @override
  Future<void> cacheProcessedTransactionIds(List<String> ids) async {}

  @override
  void dispose() {}

  @override
  TaskEither<AppException, List<IapProductEntity>> getProducts(GetPackagesParams params) {
    return TaskEither.tryCatch(
      () async {
        getProductsCalls++;
        return products;
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, PaywallConfigEntity> getPaywallConfig() {
    return TaskEither.tryCatch(
      () async {
        getPaywallConfigCalls++;
        final delay = this.delay;
        if (delay != null) await Future<void>.delayed(delay);
        if (shouldFail) throw Exception('network down');
        return nextConfig ?? const PaywallConfigEntity();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  Future<List<String>> loadProcessedTransactionIds() async => [];

  @override
  TaskEither<AppException, IapVerifyEntity> purchase(PurchaseParams params) => TaskEither.right(const IapVerifyEntity());

  @override
  TaskEither<AppException, IapVerifyEntity> restore() => TaskEither.right(const IapVerifyEntity());

  @override
  TaskEither<AppException, IapVerifyEntity> verify(VerifyParams params) => TaskEither.right(const IapVerifyEntity());

  @override
  TaskEither<AppException, VoucherValidationEntity> validateVoucher(ValidateVoucherParams params) => TaskEither.right(const VoucherValidationEntity());

  @override
  TaskEither<AppException, PaywallLogicSaleEntity> getLogicSale() => TaskEither.right(const PaywallLogicSaleEntity());
}

class _FakeIapService implements IIapService {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {}

  @override
  Future<List<ProductDetails>> getProducts({required Set<String> productIds}) async => [];

  @override
  Future<bool> purchaseProduct(String productId, ProductType type) async => true;

  @override
  Future<PurchaseVerificationData?> refreshIOSVerificationData() async => null;

  @override
  Future<void> restorePurchases() async {}
}

class _FakeRemoteConfigService implements IRemoteConfigService {
  PaywallConfigEntity config;

  _FakeRemoteConfigService(this.config);

  @override
  AppFunctionEntity get appFunction => const AppFunctionEntity();

  @override
  AppVersionConfigEntity get appVersionConfig => const AppVersionConfigEntity();

  @override
  CourseConfigEntity get courseConfig => const CourseConfigEntity();

  @override
  Future<void> initialize() async {}

  @override
  OnboardingConfigEntity get onboardingConfig => const OnboardingConfigEntity();

  @override
  PaywallConfigEntity get paywallConfig => config;

  @override
  Future<bool> updateAvailable() async => false;
}

class _FakePackageInfoService implements IPackageInfoService {
  @override
  String get appName => 'Meup';

  @override
  String get buildNumber => '1';

  @override
  String get fullVersion => '1.0.0+1';

  @override
  Future<void> initialize() async {}

  @override
  bool isVersionLowerThan(String targetVersion) => false;

  @override
  String get packageName => 'com.meup.test';

  @override
  PackageInfo get packageInfo => PackageInfo(appName: appName, packageName: packageName, version: version, buildNumber: buildNumber);

  @override
  Map<String, dynamic> toMap() => {};

  @override
  String get version => '1.0.0';
}

class _FakeTrackingService extends Mock implements ITrackingService {}
