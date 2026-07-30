library;

import 'dart:math' as math;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/monetization_local_data_source.dart';
part 'data/datasources/local/paywall_config_local_data_source.dart';
part 'data/datasources/local/user_subscription_local_data_source.dart';
part 'data/datasources/remote/monetization_api.dart';
part 'data/datasources/remote/paywall_config_api.dart';
part 'data/datasources/remote/user_subscription_api.dart';
part 'data/models/iap_product_model.dart';
part 'data/models/iap_subscription_model.dart';
part 'data/models/iap_verify_model.dart';
part 'data/models/voucher_validation_model.dart';
part 'data/repositories/monetization_repository.dart';
part 'data/repositories/user_subscription_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/iap_product_entity.dart';
part 'domain/entities/iap_subscription_entity.dart';
part 'domain/entities/iap_verify_entity.dart';
part 'domain/entities/resolved_paywall_strategy_entity.dart';
part 'domain/entities/voucher_validation_entity.dart';
part 'domain/repositories/i_monetization_repository.dart';
part 'domain/repositories/i_user_subscription_repository.dart';
part 'domain/usecases/get_packages_usecase.dart';
part 'domain/usecases/get_paywall_config_usecase.dart';
part 'domain/usecases/get_user_iap_subscriptions_usecase.dart';
part 'domain/usecases/purchase_usecase.dart';
part 'domain/usecases/resolve_paywall_strategy_usecase.dart';
part 'domain/usecases/restore_usecase.dart';
part 'domain/usecases/validate_voucher_usecase.dart';
part 'domain/usecases/verify_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'monetization.freezed.dart';
part 'monetization.g.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/iap_cubit.dart';
part 'presentation/cubits/iap_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/paywall_page.dart';
part 'presentation/pages/user_subcription_page.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/paywall/paywall_banner_carousel.dart';
part 'presentation/widgets/paywall/paywall_benefit_rows.dart';
part 'presentation/widgets/paywall/paywall_bottom_purchase_bar.dart';
part 'presentation/widgets/paywall/paywall_countdown_strip.dart';
part 'presentation/widgets/paywall/paywall_dots_indicator.dart';
part 'presentation/widgets/paywall/paywall_feedback_list.dart';
part 'presentation/widgets/paywall/paywall_highlight_package_info.dart';
part 'presentation/widgets/paywall/paywall_inline_plans.dart';
part 'presentation/widgets/paywall/paywall_legal_links.dart';
part 'presentation/widgets/paywall/paywall_page_decoration.dart';
part 'presentation/widgets/paywall/paywall_plan_option.dart';
part 'presentation/widgets/paywall/paywall_plan_option_badges.dart';
part 'presentation/widgets/paywall/paywall_promo_code.dart';
part 'presentation/widgets/paywall/paywall_promo_code_sheet.dart';
part 'presentation/widgets/paywall/paywall_purchase_button.dart';
part 'presentation/widgets/paywall/paywall_success_purchase_popup.dart';
part 'presentation/widgets/paywall/paywall_top_bar.dart';
part 'presentation/widgets/user_subcription/user_subscription_active_card.dart';
part 'presentation/widgets/user_subcription/user_subscription_empty_state.dart';
part 'presentation/widgets/user_subcription/user_subscription_header.dart';
