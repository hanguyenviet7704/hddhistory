library;

//* Import all default dart libraries here
import 'dart:async';
import 'dart:io';

//* Import all dependencies here
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:darq/darq.dart';
import 'package:flutter/foundation.dart' hide kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/src/auth/auth.dart';

//* Import all local files here
import '../../../../config/di/di.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/services/services.dart';
import '../../../../config/share/share.dart';
import '../../../../config/themes/themes.dart';
import '../../../../core/base/base.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/helpers/helpers.dart';
import '../../../../flavors.dart';
import '../../data/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/usecases.dart';

//* Export all the blocs here

//? Base Bloc
part 'blocs.freezed.dart';
part 'blocs.g.dart';
//? Connectivity Bloc
part 'connectivity/connectivity_cubit.dart';
part 'connectivity/connectivity_state.dart';
//? Page Bloc
part 'page/page_cubit.dart';
part 'page/page_state.dart';
//? In App Bloc
part 'paywall/iap/iap_cubit.dart';
part 'paywall/iap/iap_state.dart';
//? Paywall Bloc
part 'paywall/paywall/paywall_cubit.dart';
part 'paywall/paywall/paywall_state.dart';
//? Setting Bloc
part 'setting/locale_cubit.dart';
part 'setting/theme_cubit.dart';
part 'setting/theme_mode_cubit.dart';

//
// part 'preview_lecture/preview_lecture_cubit.dart';
// part 'preview_lecture/preview_lecture_state.dart';
