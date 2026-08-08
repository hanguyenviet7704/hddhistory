library;

//* Import all default dart here
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as df;
//* Import all dependency here
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

//* Import all files here
import '../../config/di/di.dart';
import '../../config/l10n/l10n.g.dart';
import '../../config/routes/routes.dart';
import '../../config/services/services.dart';
import '../../config/themes/themes.dart';
import '../../src/common/common.dart';
import '../../src/learning_streak/learning_streak.dart';
import '../../src/monetization/monetization.dart';
import '../../src/study_theme/study_theme.dart';
import '../constants/constants.dart';
import '../helpers/helpers.dart';

//* Export all animation files
part 'animation/page_transition.dart';
part 'haptic/app_haptic.dart';
//* Export all button files
part 'button/app_button.dart';
part 'button/button.dart';
part 'button/cta_button.dart';
part 'button/gradient_button.dart';
part 'images/cache_network_graphic.dart';
//* Export all images files
part 'images/cache_image.dart';
part 'images/cache_lottie.dart';
//* Export all input files
part 'input/text_field.dart';
part 'layouts/error_layout.dart';
//* Export all layout files
part 'layouts/scaffod_layout.dart';
//* Export all navbar files
part 'navbar/bottom_nav.dart';
part 'navbar/nav_bar_items.dart';
//* Export all overlay files
part 'overlay/about_dialog.dart';
part 'overlay/bottom_sheet.dart';
part 'overlay/data_bottom_sheet.dart';
part 'overlay/dialog.dart';
part 'overlay/message.dart';
part 'overlay/notification_dialog.dart';
part 'overlay/yes_no_dialog.dart';
//* Export all sliver files
part 'sliver/sliver_child.dart';
//* Export all tab files
part 'tab/filter_tab_bar.dart';
//* Export all text files
part 'text/d_text.dart';
// part 'text/expandable_html_text.dart';
part 'text/expandable_text.dart';
part 'text/gradient_text.dart';
part 'text/high_light_text.dart';
//* Export all timer files
part 'timer/count_down.dart';
// part 'video/video_view.dart';
//* Export all webview files
part 'webview/web_view.dart';
//* Export all wrap files
part 'wrap/gradient_box_border.dart';
part 'wrap/gradient_typography.dart';
part 'wrap/load_more.dart';
part 'wrap/safe_body.dart';
part 'wrap/unfocused.dart';

// import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
// import 'package:lottie/lottie.dart';
// import 'package:video_player/video_player.dart';
