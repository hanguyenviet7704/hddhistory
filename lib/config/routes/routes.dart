library;

//* Import all default dart libraries here
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

//* Import all dependencies here
import '../../core/utils/utils.dart';
import '../../src/src.dart';
import '../di/di.dart';
import '../services/services.dart';
import '../themes/themes.dart';

//* Import all dependencies here

//* Export all routes here
part 'base/app_pages.dart';
part 'base/app_routes.dart';
part 'base/app_routes_config.dart';
part 'data/routes_auth_data.dart';
part 'data/routes_common_data.dart';
part 'data/routes_onboard_data.dart';
part 'data/routes_shell.dart';
part 'data/routes_shell_course_data.dart';
part 'data/routes_shell_course_lesson_data.dart';
part 'data/routes_shell_course_output_practice_data.dart';
part 'data/routes_shell_course_video_lesson_data.dart';
part 'data/routes_shell_course_roleplay_data.dart';
part 'data/routes_shell_home_data.dart';
part 'data/routes_shell_setting_data.dart';
part 'routes.g.dart';
