import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('IapCubit strategy loading', () {
    late _FakeMonetizationRepository repository;
    late _FakeRemoteConfigService remoteConfig;
    late IapCubit cubit;

    setUp(() {
      repository = _FakeMonetizationRepository();
      remoteConfig = _FakeRemoteConfigService(_configWithProducts(['annual', 'quarter']));
      cubit = IapCubit(
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
        _FakePackageInfoService(),
      );
    });

    test('selects first best deal and reuses matching signature cache', () async {
      repository.products = const [
        IapProductEntity(id: 'row-annual', productId: 'annual'),
        IapProductEntity(id: 'row-quarter', productId: 'quarter', bestDeal: true),
      ];

      expect(await cubit.loadIapProducts(), isTrue);
      expect(cubit.state.status, MonetizationStatus.success);
      expect(cubit.state.selectedProductId, 'row-quarter');
      expect(cubit.state.iapProducts.map((product) => product.productId), ['annual', 'quarter']);
      expect(repository.getProductsCalls, 1);

      expect(await cubit.loadIapProducts(), isTrue);
      expect(repository.getProductsCalls, 1);
    });

    test('shares an in-flight load for the same strategy signature', () async {
      repository.delay = const Duration(milliseconds: 20);
      repository.products = const [
        IapProductEntity(id: 'row-annual', productId: 'annual'),
        IapProductEntity(id: 'row-quarter', productId: 'quarter'),
      ];

      final results = await Future.wait([cubit.loadIapProducts(), cubit.loadIapProducts()]);

      expect(results, [true, true]);
      expect(repository.getProductsCalls, 1);
    });

    test('force retry cannot be overwritten by older same-signature in-flight load', () async {
      repository.delay = const Duration(milliseconds: 20);
      repository.queuedProducts = [
        const [IapProductEntity(id: 'old-row', productId: 'annual')],
        const [IapProductEntity(id: 'fresh-row', productId: 'annual', bestDeal: true)],
      ];

      final firstLoad = cubit.loadIapProducts();
      await Future<void>.delayed(Duration.zero);
      final retry = await cubit.loadIapProducts(forceRetry: true);
      final firstResult = await firstLoad;

      expect(firstResult, isFalse);
      expect(retry, isTrue);
      expect(repository.getProductsCalls, 2);
      expect(cubit.state.iapProducts.single.id, 'fresh-row');
    });

    test('invalid strategy fails closed and does not query products', () async {
      remoteConfig.config = const PaywallConfigEntity(schemaVersion: 2);

      expect(await cubit.loadIapProducts(), isFalse);

      expect(cubit.state.status, MonetizationStatus.failure);
      expect(cubit.state.iapProducts, isEmpty);
      expect(repository.getProductsCalls, 0);
    });

    test('auto-open prepares products once, sets entry point, and dedupes concurrent calls', () async {
      remoteConfig.config = _configWithProducts(['annual'], autoOpenPercent: 100);
      repository.delay = const Duration(milliseconds: 20);
      repository.products = const [IapProductEntity(id: 'row-annual', productId: 'annual')];
      cubit.debugSetAutoOpenRolloutBucket(0);
      var refreshCalls = 0;

      final results = await Future.wait([
        cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: false,
          refreshPremiumStatus: () async {
            refreshCalls++;
            return false;
          },
        ),
        cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: false,
          refreshPremiumStatus: () async {
            refreshCalls++;
            return false;
          },
        ),
      ]);

      expect(results, [true, true]);
      expect(refreshCalls, 1);
      expect(repository.getProductsCalls, 1);
      expect(cubit.paywallEntryPoint, PaywallEntryPoint.autoOpen);

      final third = await cubit.prepareAutoOpenPaywall(
        userId: 'user-1',
        accessToken: 'token',
        hasCompletedOnboarding: true,
        isPremium: false,
        refreshPremiumStatus: () async => false,
      );
      expect(third, isFalse);
      expect(repository.getProductsCalls, 1);
    });

    test('auto-open fails closed for premium, unknown refresh, suppression, and product failure', () async {
      remoteConfig.config = _configWithProducts(['annual'], autoOpenPercent: 100);
      repository.products = const [IapProductEntity(id: 'row-annual', productId: 'annual')];
      cubit.debugSetAutoOpenRolloutBucket(0);

      expect(
        await cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: true,
          refreshPremiumStatus: () async => false,
        ),
        isFalse,
      );
      expect(repository.getProductsCalls, 0);

      cubit = _newCubit(repository, remoteConfig)..debugSetAutoOpenRolloutBucket(0);
      expect(
        await cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: false,
          refreshPremiumStatus: () async => null,
        ),
        isFalse,
      );
      expect(repository.getProductsCalls, 0);

      cubit = _newCubit(repository, remoteConfig)
        ..debugSetAutoOpenRolloutBucket(0)
        ..suppressPaywallAutoOpenForSession();
      expect(
        await cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: false,
          refreshPremiumStatus: () async => false,
        ),
        isFalse,
      );

      repository.products = const [];
      cubit = _newCubit(repository, remoteConfig)..debugSetAutoOpenRolloutBucket(0);
      expect(
        await cubit.prepareAutoOpenPaywall(
          userId: 'user-1',
          accessToken: 'token',
          hasCompletedOnboarding: true,
          isPremium: false,
          refreshPremiumStatus: () async => false,
        ),
        isFalse,
      );
      expect(cubit.paywallEntryPoint, PaywallEntryPoint.other);
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
    _FakePackageInfoService(),
  );
}

PaywallConfigEntity _configWithProducts(List<String> productIds, {int autoOpenPercent = 0}) {
  return PaywallConfigEntity(
    schemaVersion: 2,
    autoOpen: PaywallAutoOpenEntity(
      enabled: autoOpenPercent > 0,
      sessionRolloutPercent: autoOpenPercent,
    ),
    saleStrategy: PaywallSaleStrategyEntity(
      defaultUser: PaywallDefaultUserStrategyEntity(
        content: const PaywallContentEntity(heading: BaseMultiLanguage(en: 'Heading')),
        products: [
          for (final id in productIds) PaywallProductReferenceEntity(appleProductId: id, googleProductId: id),
        ],
      ),
    ),
  );
}

class _FakeMonetizationRepository implements IMonetizationRepository {
  List<IapProductEntity> products = const [];
  List<List<IapProductEntity>> queuedProducts = const [];
  int getProductsCalls = 0;
  Duration? delay;
  // Simulates "no live API data and no cache yet" by default, so
  // IapCubit.resolvedPaywallConfig keeps deferring to the injected
  // `_FakeRemoteConfigService` exactly like these tests expect — tests that
  // care about the API layer itself live in
  // test/unit/monetization/data/repositories/monetization_repository_paywall_config_test.dart
  // and a dedicated IapCubit fallback test.
  PaywallConfigEntity? apiPaywallConfig;

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
        final delay = this.delay;
        if (delay != null) await Future<void>.delayed(delay);
        if (queuedProducts.isNotEmpty) {
          final nextProducts = queuedProducts.first;
          queuedProducts = queuedProducts.skip(1).toList();
          return nextProducts;
        }
        return products;
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
  TaskEither<AppException, PaywallConfigEntity> getPaywallConfig() {
    final config = apiPaywallConfig;
    if (config == null) return TaskEither.left(AppException.unexpected('not_configured'));
    return TaskEither.right(config);
  }
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
