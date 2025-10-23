library;

import 'dart:math' as math;
import 'dart:ui' as ui;

//* Package imports
//* Single project import
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrofit/retrofit.dart';

part 'data/datasources/local/exercise_local_data_source.dart';
part 'data/datasources/remote/exercise_api.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/models/exercise_model.dart';
part 'data/repositories/exercise_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/exercise_entity.dart';
part 'domain/repositories/i_exercise_repository.dart';
part 'domain/usecases/create_exercise_usecase.dart';
part 'domain/usecases/delete_exercise_usecase.dart';
part 'domain/usecases/get_all_exercises_usecase.dart';
part 'domain/usecases/get_exercise_usecase.dart';
part 'domain/usecases/update_exercise_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'exercise.freezed.dart';
part 'exercise.g.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/exercise_cubit.dart';
part 'presentation/cubits/exercise_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/example/arrange_the_sequence_screen.dart';
part 'presentation/pages/example/choise_screen.dart';
part 'presentation/pages/example/cues_placement_screen.dart';
part 'presentation/pages/example/drag_and_drop_screen.dart';
part 'presentation/pages/exercise_page.dart';
part 'presentation/pages/example/speaking_screen.dart';
part 'presentation/pages/example/tap_and_jump_screen.dart';
part 'presentation/widgets/body/arrange_the_sequense_lesson_body.dart';
part 'presentation/widgets/body/cues_placement_lesson_body.dart';
part 'presentation/widgets/body/drag_and_drop_lesson_body.dart';
part 'presentation/widgets/body/multiple_choice_lesson_body.dart';
part 'presentation/widgets/body/single_choice_lesson_body.dart';
part 'presentation/widgets/body/speaking_lesson_body.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/bottom_button.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/header.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/image_card.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/practice_tag.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/question_bubble.dart';
part 'presentation/widgets/items/example/arrange_the_sequence/sequence_answer_card.dart';
part 'presentation/widgets/items/example/choise/audio_player_widget.dart';
part 'presentation/widgets/items/example/choise/choice_answer_card.dart';
part 'presentation/widgets/items/example/choise/mock_data.dart';
part 'presentation/widgets/items/example/choise/result_bottom_sheet.dart';
part 'presentation/widgets/items/common/bubble_border.dart';
part 'presentation/widgets/items/common/exercise_badge.dart';
part 'presentation/widgets/items/common/exercise_chat_bubble.dart';
part 'presentation/widgets/items/common/exercise_continue_button.dart';
part 'presentation/widgets/items/common/exercise_header.dart';
part 'presentation/widgets/items/common/exercise_progress_bar.dart';
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
part 'presentation/widgets/items/example/drag_and_drop/answer_card.dart';
part 'presentation/widgets/items/example/drag_and_drop/answer_cards_area.dart';
part 'presentation/widgets/items/example/drag_and_drop/blank_slot.dart';
part 'presentation/widgets/items/example/drag_and_drop/bottom_button.dart';
part 'presentation/widgets/items/example/drag_and_drop/dashed_border_painter.dart';
part 'presentation/widgets/items/example/drag_and_drop/header.dart';
part 'presentation/widgets/items/example/drag_and_drop/practice_tag.dart';
part 'presentation/widgets/items/example/drag_and_drop/question_bubble.dart';
part 'presentation/widgets/items/example/drag_and_drop/sentence_builder.dart';
part 'presentation/widgets/items/example/speaking/header.dart';
part 'presentation/widgets/items/example/speaking/instruction_card.dart';
part 'presentation/widgets/items/example/speaking/recording_control.dart';
part 'presentation/widgets/items/example/tap_and_jump/animated_word.dart';
part 'presentation/widgets/items/example/tap_and_jump/tap_answer_card.dart';
part 'presentation/widgets/items/example/tap_and_jump/tap_answer_cards_area.dart';
part 'presentation/widgets/items/example/tap_and_jump/tap_blank_slot.dart';
part 'presentation/widgets/items/example/tap_and_jump/tap_sentence_builder.dart';
part 'presentation/widgets/layouts/exercise_layout.dart';
