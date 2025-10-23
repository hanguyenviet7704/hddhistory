library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
//* Import all local files here
import 'package:meup/core/helpers/helpers.dart';
import 'package:meup/src/auth/auth.dart';

//* Import all dependencies here
import '../../../../config/services/services.dart';
import '../../../../core/utils/utils.dart';
import '../datasources/graphql/graphql.dart';

//* Import all models here
part 'iap/active_product.dart';
part 'iap/feature.dart';
part 'iap/iap_product.dart';
part 'iap/iap_verify.dart';
part 'iap/payment_provider.dart';
part 'info/app_intro.dart';
part 'info/contact.dart';
part 'models.freezed.dart';
part 'models.g.dart';
part 'remote_config/app_function_model.dart';
part 'user/app_user.dart';
part 'user/change_user_profile_id_model.dart';
part 'user/profile.dart';
part 'user/profile_geolocation.dart';
part 'user/profile_timestamps.dart';
