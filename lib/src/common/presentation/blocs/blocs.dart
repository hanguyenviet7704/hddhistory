library;

//* Import all default dart libraries here
import 'dart:async';

//* Import all dependencies here
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

//* Import all local files here
import '../../../../config/config.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/helpers/helpers.dart';

//* Export all the blocs here

//? Base Bloc
part 'blocs.freezed.dart';
//? Connectivity Bloc
part 'connectivity/connectivity_cubit.dart';
part 'connectivity/connectivity_state.dart';
//? Setting Bloc
part 'setting/locale_cubit.dart';
part 'setting/theme_cubit.dart';
part 'setting/theme_mode_cubit.dart';

//
// part 'preview_lecture/preview_lecture_cubit.dart';
// part 'preview_lecture/preview_lecture_state.dart';
