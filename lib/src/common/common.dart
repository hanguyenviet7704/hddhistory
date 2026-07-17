library;

//* Single project import
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:darq/darq.dart';
import 'package:meup/meup.dart';

//* Package imports
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_widget/home_widget.dart' as home_widget_plugin;
import 'package:injectable/injectable.dart';

//* Data Layer - Models, Datasources, Repositories

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/app_function_entity.dart';
part 'domain/entities/app_version_config_entity.dart';
part 'domain/entities/course_config_entity.dart';
part 'domain/entities/onboarding_config_entity.dart';
part 'domain/entities/paywall_config_entity.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/connectivity/connectivity_cubit.dart';
part 'presentation/cubits/connectivity/connectivity_state.dart';
part 'presentation/cubits/deeplink/deeplink_cubit.dart';
part 'presentation/cubits/deeplink/deeplink_state.dart';
part 'presentation/cubits/page/page_cubit.dart';
part 'presentation/cubits/page/page_state.dart';
part 'presentation/cubits/setting/haptic_setting_cubit.dart';
part 'presentation/cubits/setting/locale_cubit.dart';
part 'presentation/cubits/setting/theme_cubit.dart';
part 'presentation/cubits/setting/theme_mode_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/comming_soon_page.dart';
part 'presentation/pages/common_error_page.dart';
part 'presentation/pages/no_internet_connection.dart';
part 'presentation/pages/server_error_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'common.freezed.dart';
part 'common.g.dart';
