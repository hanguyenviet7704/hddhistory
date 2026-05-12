library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/onboard_v2_model.dart';
part 'data/datasources/remote/onboard_v2_api.dart';
part 'data/datasources/local/onboard_v2_local_data_source.dart';
part 'data/repositories/onboard_v2_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/onboard_v2_entity.dart';
part 'domain/repositories/i_onboard_v2_repository.dart';
part 'domain/usecases/get_onboard_v2_usecase.dart';
part 'domain/usecases/get_all_onboard_v2s_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/onboard_v2_state.dart';
part 'presentation/cubits/onboard_v2_cubit.dart';

//* Presentation Layer - Helpers
part 'presentation/helpers/onboard_v2_age_text_resolver.dart';
part 'presentation/helpers/onboard_v2_notification_status_mapper.dart';
part 'presentation/helpers/onboard_v2_random_course_picker.dart';
part 'presentation/helpers/onboard_v2_symptom_selection_mapper.dart';
part 'presentation/helpers/onboard_v2_tracking_helper.dart';

//* Presentation Layer - Pages
part 'presentation/pages/onboard_v2_age_page.dart';
part 'presentation/pages/onboard_v2_intro_page.dart';
part 'presentation/pages/onboard_v2_name_page.dart';
part 'presentation/pages/onboard_v2_notification_page.dart';
part 'presentation/pages/onboard_v2_page.dart';
part 'presentation/pages/onboard_v2_course_picker_page.dart';
part 'presentation/pages/onboard_v2_path_map_page.dart';
part 'presentation/pages/onboard_v2_path_selection_page.dart';
part 'presentation/pages/onboard_v2_symptom_selection_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/p1/onboard_v2_intro_carousel.dart';
part 'presentation/widgets/p1/onboard_v2_intro_carousel_card.dart';
part 'presentation/widgets/p6/onboard_v2_floating_notification_card.dart';
part 'presentation/widgets/p6/onboard_v2_notification_preview.dart';
part 'presentation/widgets/p6/onboard_v2_path_map.dart';
part 'presentation/widgets/p6/onboard_v2_path_map_node.dart';
part 'presentation/widgets/p6/onboard_v2_path_map_painter.dart';
part 'presentation/widgets/p6/onboard_v2_path_map_subtitle.dart';
part 'presentation/widgets/p8/onboard_v2_course_picker_card.dart';
part 'presentation/widgets/shared/onboard_v2_bottom_cta.dart';
part 'presentation/widgets/shared/onboard_v2_gradient_text.dart';
part 'presentation/widgets/shared/onboard_v2_progress_header.dart';
part 'presentation/widgets/shared/onboard_v2_screen_shell.dart';
part 'presentation/widgets/shared/onboard_v2_selectable_option_row.dart';

//* Parts for generated files
part 'onboard_v2.freezed.dart';
part 'onboard_v2.g.dart';
