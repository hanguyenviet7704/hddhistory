library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/onboard_v2_state.dart';
part 'presentation/cubits/onboard_v2_cubit.dart';

//* Presentation Layer - Helpers
part 'presentation/helpers/onboard_v2_age_text_resolver.dart';
part 'presentation/helpers/onboard_v2_config_mapper.dart';
part 'presentation/helpers/onboard_v2_copy_resolver.dart';
part 'presentation/helpers/onboard_v2_notification_status_mapper.dart';
part 'presentation/helpers/onboard_v2_selection_rules.dart';
part 'presentation/helpers/onboard_v2_tracking_helper.dart';

//* Presentation Layer - Pages
part 'presentation/pages/onboard_v2_intro_page.dart';
part 'presentation/pages/onboard_v2_name_page.dart';
part 'presentation/pages/onboard_v2_age_page.dart';
part 'presentation/pages/onboard_v2_branch_page.dart';
part 'presentation/pages/onboard_v2_problem_page.dart';
part 'presentation/pages/onboard_v2_desire_page.dart';
part 'presentation/pages/onboard_v2_how_page.dart';
part 'presentation/pages/onboard_v2_reminder_page.dart';
part 'presentation/pages/onboard_v2_loading_page.dart';
part 'presentation/pages/onboard_v2_result_page.dart';
part 'presentation/pages/onboard_v2_pick_theme_page.dart';
part 'presentation/pages/onboard_v2_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/p1/onboard_v2_intro_carousel.dart';
part 'presentation/widgets/p1/onboard_v2_intro_carousel_card.dart';
part 'presentation/widgets/p6/onboard_v2_floating_notification_card.dart';
part 'presentation/widgets/p6/onboard_v2_notification_preview.dart';
part 'presentation/widgets/p8/onboard_v2_time_wheel.dart';
part 'presentation/widgets/p8/onboard_v2_course_picker_card.dart';
part 'presentation/widgets/shared/onboard_v2_bottom_cta.dart';
part 'presentation/widgets/shared/onboard_v2_chip.dart';
part 'presentation/widgets/shared/onboard_v2_gradient_text.dart';
part 'presentation/widgets/shared/onboard_v2_inline_error.dart';
part 'presentation/widgets/shared/onboard_v2_progress_header.dart';
part 'presentation/widgets/shared/onboard_v2_screen_shell.dart';
part 'presentation/widgets/shared/onboard_v2_selectable_option_row.dart';

//* Parts for generated files
part 'onboard_v2.freezed.dart';
