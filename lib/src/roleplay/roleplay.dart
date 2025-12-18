library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shimmer/shimmer.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/roleplay_local_data_source.dart';
part 'data/datasources/remote/roleplay_api.dart';
part 'data/datasources/remote/roleplay_feedback_api.dart';
part 'data/models/conversation_avatar_model.dart';
part 'data/models/conversation_model.dart';
part 'data/models/leading_text_model.dart';
part 'data/models/roleplay_content_model.dart';
part 'data/models/roleplay_feedback_model.dart';
part 'data/models/roleplay_mission_model.dart';
part 'data/models/roleplay_model.dart';
part 'data/models/transition_model.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'data/repositories/roleplay_repository.dart';
part 'domain/entities/conversation_avatar_entity.dart';
part 'domain/entities/conversation_entity.dart';
part 'domain/entities/leading_text_entity.dart';
part 'domain/entities/roleplay_content_entity.dart';
part 'domain/entities/roleplay_entity.dart';
part 'domain/entities/roleplay_feedback_entity.dart';
part 'domain/entities/roleplay_mission_entity.dart';
part 'domain/entities/transition_entity.dart';
part 'domain/repositories/i_roleplay_repository.dart';
part 'domain/usecases/get_learning_item_usecase.dart';
part 'domain/usecases/send_feedback_roleplay_usecase.dart';
//* Presentation Layer - Cubits
part 'presentation/cubits/roleplay/roleplay_cubit.dart';
part 'presentation/cubits/roleplay/roleplay_state.dart';
part 'presentation/cubits/roleplay_point/roleplay_point_cubit.dart';
part 'presentation/cubits/roleplay_point/roleplay_point_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/roleplay_complete_page.dart';
part 'presentation/pages/roleplay_feedback_page.dart';
part 'presentation/pages/roleplay_intro_page.dart';
part 'presentation/pages/roleplay_page.dart';
part 'presentation/widgets/roleplay/exercise/roleplay_colapsed_exercise_body.dart';
part 'presentation/widgets/roleplay/exercise/roleplay_exercise_content_widget.dart';
part 'presentation/widgets/roleplay/exercise/roleplay_exercise_overlay.dart';
part 'presentation/widgets/roleplay/exercise/roleplay_exercise_result_overlay.dart';
part 'presentation/widgets/roleplay/exercise/roleplay_expaned_exercise_body.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/roleplay/roleplay_audio_controller.dart';
part 'presentation/widgets/roleplay/roleplay_background.dart';
part 'presentation/widgets/roleplay/roleplay_bubble_widget.dart';
part 'presentation/widgets/roleplay/roleplay_content.dart';
part 'presentation/widgets/roleplay/roleplay_content_list.dart';
part 'presentation/widgets/roleplay/roleplay_leadingtext_widget.dart';
part 'presentation/widgets/roleplay/roleplay_page_header.dart';
part 'presentation/widgets/roleplay/roleplay_transition_widget.dart';
part 'presentation/widgets/roleplay_complete/roleplay_complete_bottom_cta.dart';
part 'presentation/widgets/roleplay_complete/roleplay_complete_title.dart';
part 'presentation/widgets/roleplay_feedback/roleplay_feedback_breakdown.dart';
part 'presentation/widgets/roleplay_feedback/roleplay_feedback_chart.dart';
part 'presentation/widgets/roleplay_feedback/roleplay_feedback_cta.dart';
part 'presentation/widgets/roleplay_feedback/roleplay_feedback_indicator.dart';
part 'presentation/widgets/roleplay_feedback/roleplay_feedback_summary.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_action_button.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_background.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_details.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_hero_card.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_missions.dart';
part 'presentation/widgets/roleplay_intro/roleplay_intro_time_chip.dart';
//* Parts for generated files
part 'roleplay.freezed.dart';
part 'roleplay.g.dart';
