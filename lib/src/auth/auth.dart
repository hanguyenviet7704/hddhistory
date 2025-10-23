library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';
import 'package:uuid/uuid.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'auth.freezed.dart';
part 'auth.g.dart';
part 'data/datasources/local/auth_local_data_source.dart';
part 'data/datasources/remote/auth_api.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/models/auth_model.dart';
part 'data/models/token_model.dart';
part 'data/repositories/auth_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/auth_entity.dart';
part 'domain/entities/token_entity.dart';
part 'domain/repositories/i_auth_repository.dart';
part 'domain/usecases/delete_account_usecase.dart';
part 'domain/usecases/delete_permanent_user_usecase.dart';
part 'domain/usecases/forgot_password_usecase.dart';
part 'domain/usecases/login_anonymous_usecase.dart';
part 'domain/usecases/login_sso_apple_usecase.dart';
part 'domain/usecases/login_sso_google_usecase.dart';
part 'domain/usecases/login_usecase.dart';
part 'domain/usecases/logout_usecase.dart';
part 'domain/usecases/register_usecase.dart';
part 'domain/usecases/resend_otp_usecase.dart';
part 'domain/usecases/reset_password_usecase.dart';
part 'domain/usecases/update_password_usecase.dart';
part 'domain/usecases/verify_otp_usecase.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/blocs/auth_bloc.dart';
part 'presentation/blocs/auth_event.dart';
part 'presentation/blocs/auth_state.dart';
part 'presentation/cubits/user_cubit.dart';
part 'presentation/cubits/user_state.dart';
//* Presentation Layer - Pages
//? Change Password
part 'presentation/pages/change_password/change_password.dart';
//? Forgot Password
part 'presentation/pages/forgot_pass/forgot_pass_page.dart';
part 'presentation/pages/forgot_pass/setup_pass_page.dart';
//? Login
part 'presentation/pages/login/login_page.dart';
//? No Auth
part 'presentation/pages/no_auth/no_auth_page.dart';
//? OTP
part 'presentation/pages/otp/otp_page.dart';
//? Register
part 'presentation/pages/register/register_page.dart';
//? Widgets
part 'presentation/widgets/items/animate_switch.dart';
part 'presentation/widgets/items/apple_login_button.dart';
part 'presentation/widgets/items/close_button.dart';
part 'presentation/widgets/items/google_login_button.dart';
part 'presentation/widgets/items/guest_login_button.dart';
part 'presentation/widgets/items/language_button.dart';
part 'presentation/widgets/items/menu_option.dart';
part 'presentation/widgets/items/nodata.dart';
part 'presentation/widgets/items/preminum_upgrade_intro.dart';
part 'presentation/widgets/items/social_login_button.dart';
//? Layouts
part 'presentation/widgets/layouts/auth_layout.dart';
part 'presentation/widgets/layouts/sub_layout.dart';
