library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Package imports
//* Single project import
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:meup/meup.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/exercise_local_data_source.dart';
part 'data/datasources/remote/exercise_api.dart';
part 'data/models/answer_model.dart';
part 'data/models/content_document_model.dart';
part 'data/models/document_data_model.dart';
part 'data/models/document_model.dart';
part 'data/models/learning_item_model.dart';
part 'data/models/option_model.dart';
part 'data/models/question_model.dart';
part 'data/models/tag_model.dart';
part 'data/repositories/exercise_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/answer_entity.dart';
part 'domain/entities/content_document_entity.dart';
part 'domain/entities/document_data_entity.dart';
part 'domain/entities/document_entity.dart';
part 'domain/entities/exercise_entity.dart';
part 'domain/entities/learning_item_entity.dart';
part 'domain/entities/option_entity.dart';
part 'domain/entities/question_entity.dart';
part 'domain/entities/tag_entity.dart';
part 'domain/repositories/i_exercise_repository.dart';
part 'domain/usecases/get_all_learning_items_usecase.dart';
part 'domain/usecases/get_learning_item_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'exercise.freezed.dart';
part 'exercise.g.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/arrange_the_sequence/arrange_the_sequence_cubit.dart';
part 'presentation/cubits/arrange_the_sequence/arrange_the_sequence_state.dart';
part 'presentation/cubits/choice/choice_cubit.dart';
part 'presentation/cubits/choice/choice_state.dart';
part 'presentation/cubits/cues_placement/cues_placement_cubit.dart';
part 'presentation/cubits/cues_placement/cues_placement_state.dart';
part 'presentation/cubits/drag_and_drop/drag_and_drop_cubit.dart';
part 'presentation/cubits/drag_and_drop/drag_and_drop_state.dart';
part 'presentation/cubits/exercise/exercise_cubit.dart';
part 'presentation/cubits/exercise/exercise_state.dart';
part 'presentation/cubits/mark_stress_word/mark_stress_word_cubit.dart';
part 'presentation/cubits/mark_stress_word/mark_stress_word_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/example/cues_placement_screen.dart';
part 'presentation/pages/example/speaking_screen.dart';
part 'presentation/pages/exercise_page.dart';
part 'presentation/widgets/body/arrange_the_sequense_lesson_body.dart';
part 'presentation/widgets/body/cues_placement_lesson_body.dart';
part 'presentation/widgets/body/drag_and_drop_lesson_body.dart';
part 'presentation/widgets/body/mark_stress_word_lesson_body.dart';
part 'presentation/widgets/body/multiple_choice_lesson_body.dart';
part 'presentation/widgets/body/single_choice_lesson_body.dart';
part 'presentation/widgets/body/speaking_lesson_body.dart';
part 'presentation/widgets/items/arrange_the_sequence/arrange_sequence_answer_card.dart';
part 'presentation/widgets/items/arrange_the_sequence/arrange_sequence_result_bottom_sheet.dart';
part 'presentation/widgets/items/choice/audio_player_widget.dart';
part 'presentation/widgets/items/choice/choice_answer_card.dart';
part 'presentation/widgets/items/choice/choice_document_item.dart';
part 'presentation/widgets/items/choice/choice_document_widget.dart';
part 'presentation/widgets/items/choice/custom_slider_thumb_shape.dart';
part 'presentation/widgets/items/choice/mock_data.dart';
part 'presentation/widgets/items/choice/multiple_choice_answer_card.dart';
part 'presentation/widgets/items/choice/result_bottom_sheet.dart';
part 'presentation/widgets/items/common/bubble_border.dart';
part 'presentation/widgets/items/common/exercise_badge.dart';
part 'presentation/widgets/items/common/exercise_chat_bubble.dart';
part 'presentation/widgets/items/common/exercise_continue_button.dart';
part 'presentation/widgets/items/common/exercise_header.dart';
part 'presentation/widgets/items/common/exercise_progress_bar.dart';
part 'presentation/widgets/items/drag_and_drop/answer_card.dart';
part 'presentation/widgets/items/drag_and_drop/answer_cards_area.dart';
part 'presentation/widgets/items/drag_and_drop/blank_slot.dart';
part 'presentation/widgets/items/drag_and_drop/empty_slot.dart';
part 'presentation/widgets/items/drag_and_drop/filled_slot.dart';
part 'presentation/widgets/items/drag_and_drop/result_bottom_sheet.dart';
part 'presentation/widgets/items/drag_and_drop/sentence_builder.dart';
part 'presentation/widgets/items/cues_placement/cues_placement_pause_mark.dart';
part 'presentation/widgets/items/cues_placement/cues_placement_pause_mark_icon.dart';
part 'presentation/widgets/items/cues_placement/cues_placement_word_with_drop_zone.dart';
part 'presentation/widgets/items/cues_placement/cues_placement_available_marks.dart';
part 'presentation/widgets/items/cues_placement/cues_placement_result_bottom_sheet.dart';
part 'presentation/widgets/items/example/cues_placement/available_pause_marks.dart';
part 'presentation/widgets/items/example/cues_placement/avatar.dart';
part 'presentation/widgets/items/example/cues_placement/bottom_button.dart';
part 'presentation/widgets/items/example/cues_placement/bubble_tail_painter.dart';
part 'presentation/widgets/items/example/cues_placement/draggable_pause_mark.dart';
part 'presentation/widgets/items/example/cues_placement/home_indicator.dart';
part 'presentation/widgets/items/example/cues_placement/instruction_bubble.dart';
part 'presentation/widgets/items/example/cues_placement/pause_mark_icon.dart';
part 'presentation/widgets/items/example/cues_placement/practice_tag.dart';
part 'presentation/widgets/items/example/cues_placement/progress_bar.dart';
part 'presentation/widgets/items/example/cues_placement/status_bar.dart';
part 'presentation/widgets/items/example/cues_placement/text_bubble.dart';
part 'presentation/widgets/items/example/cues_placement/word_card.dart';
part 'presentation/widgets/items/example/cues_placement/word_grid.dart';
part 'presentation/widgets/items/example/cues_placement/word_with_drop_target.dart';
part 'presentation/widgets/items/example/speaking/header.dart';
part 'presentation/widgets/items/example/speaking/instruction_card.dart';
part 'presentation/widgets/items/example/speaking/recording_control.dart';
part 'presentation/widgets/items/mark_stress_word/mark_stress_word_card.dart';
part 'presentation/widgets/items/mark_stress_word/mark_stress_word_result_bottom_sheet.dart';
part 'presentation/widgets/layouts/exercise_layout.dart';
