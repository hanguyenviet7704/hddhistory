library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Package imports
import 'package:darq/darq.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/roleplay_local_data_source.dart';
part 'data/datasources/remote/roleplay_api.dart';
part 'data/models/conversation_avatar_model.dart';
part 'data/models/conversation_model.dart';
part 'data/models/hint_model.dart';
part 'data/models/leading_text_model.dart';
part 'data/models/section_content_model.dart';
part 'data/models/section_model.dart';
part 'data/repositories/roleplay_repository.dart';
part 'domain/entities/conversation_avatar_entity.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/conversation_entity.dart';
part 'domain/entities/hint_entity.dart';
part 'domain/entities/leading_text_entity.dart';
part 'domain/entities/section_content_entity.dart';
part 'domain/entities/section_entity.dart';
part 'domain/repositories/i_roleplay_repository.dart';
part 'domain/usecases/get_learning_item_usecase.dart';
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
//* Presentation Layer - Widgets
part 'presentation/widgets/roleplay/roleplay_audio_controller.dart';
part 'presentation/widgets/roleplay/roleplay_background.dart';
part 'presentation/widgets/roleplay/roleplay_bottom_action.dart';
part 'presentation/widgets/roleplay/roleplay_bubble_widget.dart';
part 'presentation/widgets/roleplay/roleplay_content_list.dart';
part 'presentation/widgets/roleplay/roleplay_hintext_widget.dart';
part 'presentation/widgets/roleplay/roleplay_leadingtext_widget.dart';
part 'presentation/widgets/roleplay/roleplay_page_header.dart';
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
//* Parts for generated files
part 'roleplay.freezed.dart';
part 'roleplay.g.dart';
