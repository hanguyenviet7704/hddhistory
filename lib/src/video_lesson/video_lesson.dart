library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'dart:ui' show ImageFilter;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:video_player/video_player.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_video_lesson_note_model.dart';
part 'data/models/video_question_model.dart';
part 'data/models/lesson_video_model.dart';
part 'data/datasources/remote/video_lesson_api.dart';
part 'data/datasources/local/video_lesson_local_data_source.dart';
part 'data/repositories/video_lesson_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/user_video_lesson_note_entity.dart';
part 'domain/entities/user_video_lesson_note_entity_quill_extension.dart';
part 'domain/entities/video_question_entity.dart';
part 'domain/entities/lesson_video_entity.dart';
part 'domain/entities/video_lesson_note_filter_entity.dart';
part 'domain/repositories/i_video_lesson_repository.dart';
part 'domain/usecases/get_all_user_video_lesson_notes_usecase.dart';
part 'domain/usecases/get_learning_item_usecase.dart';
part 'domain/usecases/create_user_video_lesson_note_usecase.dart';
part 'domain/usecases/update_user_video_lesson_note_usecase.dart';
part 'domain/usecases/delete_user_video_lesson_note_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/video_lesson_runtime_models.dart';
part 'presentation/cubits/video_lesson_state.dart';
part 'presentation/cubits/video_lesson_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/video_lesson_page.dart';
part 'presentation/pages/video_lesson_page_controller_actions.dart';
part 'presentation/pages/video_lesson_page_completion_utils.dart';
part 'presentation/pages/video_lesson_page_interaction_actions.dart';
part 'presentation/pages/video_lesson_page_overlay_actions.dart';
part 'presentation/pages/video_lesson_page_player_view_state.dart';
part 'presentation/pages/video_lesson_page_views.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/video_lesson_blocking_overlay_layout.dart';
part 'presentation/widgets/video_lesson_end_sheet.dart';
part 'presentation/widgets/video_lesson_intro_sheet.dart';
part 'presentation/widgets/video_lesson_notes_sheet.dart';
part 'presentation/widgets/video_lesson_notes_sheet_editor.dart';
part 'presentation/widgets/video_lesson_notes_sheet_editor_toolbar.dart';
part 'presentation/widgets/video_lesson_notes_sheet_list.dart';
part 'presentation/widgets/video_lesson_notes_sheet_note_preview.dart';
part 'presentation/widgets/video_lesson_player_controls.dart';
part 'presentation/widgets/video_lesson_player_surface.dart';
part 'presentation/widgets/video_lesson_question_result_sheet.dart';
part 'presentation/widgets/video_lesson_question_sheet.dart';
part 'presentation/widgets/video_lesson_summary_sheet.dart';

//* Parts for generated files
part 'video_lesson.freezed.dart';
part 'video_lesson.g.dart';
