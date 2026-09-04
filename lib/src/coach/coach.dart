library;

//* Dart imports
// `dartui.Path` because retrofit exports a `Path` of its own — the @Path
// annotation coach_api.dart needs. NOT prefixed `ui`: the turn model has a
// field called `ui`, and the prefix would swallow every `turn.ui.something`
// in the entity mappers.
import 'dart:ui' as dartui;

//* Flutter imports
// Ticker alone: material re-exports TickerProvider but not the Ticker class
// itself, and the slime drives its whole animation off one raw ticker.
import 'package:flutter/scheduler.dart' show Ticker;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:record/record.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/coach_model.dart';
part 'data/datasources/remote/coach_api.dart';
part 'data/repositories/coach_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/coach_entity.dart';
part 'domain/repositories/i_coach_repository.dart';
part 'domain/usecases/get_coach_bubble_usecase.dart';
part 'domain/usecases/open_coach_session_usecase.dart';
part 'domain/usecases/send_coach_turn_usecase.dart';
part 'domain/usecases/close_coach_session_usecase.dart';
part 'domain/usecases/exit_coach_session_usecase.dart';
part 'domain/usecases/transcribe_coach_audio_usecase.dart';
part 'domain/usecases/explain_again_usecase.dart';
part 'domain/usecases/set_coach_persona_usecase.dart';

//* Presentation Layer - Cubits
part 'presentation/cubits/coach_bubble_state.dart';
part 'presentation/cubits/coach_bubble_cubit.dart';
part 'presentation/cubits/coach_state.dart';
part 'presentation/cubits/coach_cubit.dart';
part 'presentation/cubits/coach_recorder.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/coach_style.dart';
part 'presentation/widgets/coach_slime.dart';
part 'presentation/widgets/coach_prompt_map.dart';
part 'presentation/widgets/coach_bubble.dart';
part 'presentation/widgets/coach_sheet.dart';
part 'presentation/widgets/coach_bubble_host.dart';
part 'presentation/widgets/coach_keypoint_invite.dart';
part 'presentation/widgets/coach_message_list.dart';
part 'presentation/widgets/coach_composer.dart';
part 'presentation/widgets/coach_two_columns.dart';
part 'presentation/widgets/coach_safety_panel.dart';
part 'presentation/widgets/coach_exit_plea_sheet.dart';

//* Parts for generated files
part 'coach.freezed.dart';
part 'coach.g.dart';
