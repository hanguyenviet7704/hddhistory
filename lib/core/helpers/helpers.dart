library;

//* Import all default dart libraries here
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
// import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
//* Import all dependencies here
import 'package:meup/core/core.dart';

//* Import all local files here
import '../../config/di/di.dart';
import '../../config/l10n/generated/strings.g.dart';
import '../../config/services/services.dart';
import '../../config/share/share.dart';
import '../../config/themes/themes.dart';
import '../../src/src.dart';

//* Import all helper here
part 'annotation/parser_anotation.dart';
part 'extension/data.dart';
part 'extension/object.dart';
part 'log/logger.dart';
part 'navigation/navigator.dart';
part 'popup/message.dart';
part 'popup/noti_message.dart';
part 'popup/overlay.dart';
part 'provider/app_providers.dart';
