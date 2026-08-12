library;

//* Package imports
//* Single project import
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:retrofit/retrofit.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;
import 'package:timeline_tile_plus/timeline_tile_plus.dart';

//* Parts for generated files
part 'course.freezed.dart';
part 'course.g.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/course_lesson_local_data_source.dart';
part 'data/datasources/local/course_local_data_source.dart';
part 'data/datasources/remote/course_api.dart';
part 'data/datasources/remote/course_lesson_api.dart';
part 'data/models/course_model.dart';
part 'data/models/keypoint_audio_model.dart';
part 'data/models/search_history_model.dart';
part 'data/models/keypoint_model.dart';
part 'data/models/learning_item_model.dart';
part 'data/models/roadmap_level_model.dart';
part 'data/models/roadmap_model.dart';
part 'data/models/roadmap_node_model.dart';
part 'data/repositories/course_lesson_repository.dart';
part 'data/repositories/course_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/course_entity.dart';
part 'domain/entities/keypoint_audio_entity.dart';
part 'domain/entities/keypoint_entity.dart';
part 'domain/entities/learning_item_entity.dart';
part 'domain/entities/roadmap_entity.dart';
part 'domain/entities/roadmap_level_entity.dart';
part 'domain/entities/roadmap_node_entity.dart';
part 'domain/helpers/course_handoff_helper.dart';
part 'domain/repositories/i_course_lesson_repository.dart';
part 'domain/repositories/i_course_repository.dart';
part 'domain/usecases/course/clear_recent_courses_usecase.dart';
part 'domain/usecases/course/clear_search_history_usecase.dart';
part 'domain/usecases/course/get_all_courses_usecase.dart';
part 'domain/usecases/course/get_course_usecase.dart';
part 'domain/usecases/course/get_recent_courses_usecase.dart';
part 'domain/usecases/course/get_roadmap_usecase.dart';
part 'domain/usecases/course/get_search_history_usecase.dart';
part 'domain/usecases/course/record_course_view_usecase.dart';
part 'domain/usecases/course/save_search_query_usecase.dart';
part 'domain/usecases/course_lesson/get_all_course_lessons_usecase.dart';
part 'domain/usecases/course_lesson/get_course_lesson_usecase.dart';
part 'presentation/cubits/course/course_cubit.dart';
part 'presentation/cubits/course/course_state.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/course_lesson/course_lesson_cubit.dart';
part 'presentation/cubits/course_lesson/course_lesson_state.dart';
part 'presentation/cubits/course_roadmap/course_roadmap_cubit.dart';
part 'presentation/cubits/course_roadmap/course_roadmap_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/change_course_page.dart';
part 'presentation/pages/course_page.dart';
part 'presentation/pages/course_roadmap_page.dart';
part 'presentation/pages/lesson_list_page.dart';
part 'presentation/pages/my_courses_page.dart';
part 'presentation/pages/skillset_courses_page.dart';
part 'presentation/helpers/explore_tracking.dart';
part 'presentation/helpers/keypoint_resume.dart';
part 'presentation/widgets/common/course_tracking_data.dart';
part 'presentation/widgets/course/all_course_tab.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/course/course_card.dart';
part 'presentation/widgets/course/course_category_chip.dart';
part 'presentation/widgets/course/course_empty_state.dart';
part 'presentation/widgets/course/course_header.dart';
part 'presentation/widgets/course/course_intro_popup.dart';
part 'presentation/widgets/course/course_lesson_empty_noti_popup.dart';
part 'presentation/widgets/course/course_list_tile.dart';
part 'presentation/widgets/course/course_search_view.dart';
part 'presentation/widgets/course/import_focus_guide.dart';
part 'presentation/widgets/course/course_tab_chip.dart';
part 'presentation/widgets/course_roadmap/course_level_content.dart';
part 'presentation/widgets/course_roadmap/completed_level_additional_content_request_card.dart';
part 'presentation/widgets/course_roadmap/completed_level_additional_content_request_options.dart';
part 'presentation/widgets/course_roadmap/completed_level_additional_content_request_popup.dart';
part 'presentation/widgets/course_roadmap/completed_level_additional_content_request_popup_controls.dart';
part 'presentation/widgets/course_roadmap/course_roadmap_content.dart';
part 'presentation/widgets/course_roadmap/course_roadmap_load_failure_state.dart';
part 'presentation/widgets/course_roadmap/course_roadmap_header_card.dart';
part 'presentation/widgets/course_roadmap/course_roadmap_floating_button.dart';
part 'presentation/widgets/course_roadmap/in_progress_badge.dart';
part 'presentation/widgets/course_roadmap/lesson_keypoint_card.dart';
part 'presentation/widgets/course_roadmap/lesson_metadata.dart';
part 'presentation/widgets/course_roadmap/roadmap_detail_popup.dart';
part 'presentation/widgets/course_roadmap/roadmap_node_item.dart';
part 'presentation/widgets/course_roadmap/roadmap_node_timeline.dart';
part 'presentation/widgets/course_roadmap/roadmap_node_content.dart';
part 'presentation/widgets/course_roadmap/roadmap_node_indicator.dart';
part 'presentation/widgets/course_roadmap/roadmap_roleplay_card.dart';
part 'presentation/widgets/course_roadmap/roadmap_session_header.dart';
part 'presentation/widgets/course_roadmap/timeline_indicator.dart';
part 'presentation/widgets/course_roadmap/top_progress_bar.dart';
part 'presentation/widgets/lesson_list/completion_check_icon.dart';
part 'presentation/widgets/lesson_list/keypoint_card.dart';
part 'presentation/widgets/lesson_list/keypoints_section_header.dart';
part 'presentation/widgets/lesson_list/lesson_description.dart';
part 'presentation/widgets/lesson_list/lesson_explain_popup.dart';
part 'presentation/widgets/lesson_list/lesson_list_header.dart';
part 'presentation/widgets/lesson_list/strength_indicator_badge.dart';
