library;

//* Import all dart default libraries here

//* Import all dependencies here
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

//* Import all local files here
import '../../../../config/services/services.dart';
import '../../../../core/base/base.dart';
import '../../data/models/models.dart';
import '../repositories/repositories.dart';

//* Import all usecases here

//? Auth usecases
part 'auth/delete_account_usecase.dart';
part 'auth/delete_permanent_user_usecase.dart';
part 'auth/forgot_password_usecase.dart';
part 'auth/login_sso_apple.dart';
part 'auth/login_sso_google.dart';
part 'auth/login_usecase.dart';
part 'auth/logout_usecase.dart';
part 'auth/register_usecase.dart';
part 'auth/resend_otp_usecase.dart';
part 'auth/reset_password_usecase.dart';
part 'auth/update_password_usecase.dart';
part 'auth/verify_otp_usecase.dart';
//? IAP usecases
part 'iap/get_packages_usecase.dart';
part 'iap/purchase_usecase.dart';
part 'iap/restore_usecase.dart';
part 'iap/verify_android_usecase.dart';
part 'iap/verify_ios_usecase.dart';
//? Profile usecases
part 'profile/get_my_profiles_usecase.dart';