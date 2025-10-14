part of 'di.dart';

@InjectableInit(
  generateForDir: [
    'lib/config/di',
    'lib/config/services',
    'lib/src/**/data/datasources/apis',
    'lib/src/**/data/datasources/sockets',
    'lib/src/**/data/repositories',
    'lib/src/**/domain/repositories',
    'lib/src/**/domain/usecases',
    'lib/src/**/presentation/blocs',
  ],
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => AppDI.injector.init();

mixin AppDI {
  static GetIt injector = GetIt.instance;

  static Future<void> initializeDependencies() async {
    injector.allowReassignment = true;
    configureDependencies();

    LogDev.data('APP DI CONFIG INITIALIZED!');
    // NetWorkDI.init(injector);
    // ApiDI.init(injector);
    // RepositoryDI.init(injector);
  }

  static Future<void> resetDependencies() async {
    await injector.reset();
    configureDependencies();
  }
}
