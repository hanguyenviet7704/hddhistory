library;

import 'dart:math' as math;

//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:lottie/lottie.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/daily_warm_up_model.dart';
part 'data/datasources/remote/daily_warm_up_api.dart';
part 'data/datasources/local/daily_warm_up_local_data_source.dart';
part 'data/repositories/daily_warm_up_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/daily_warm_up_entity.dart';
part 'domain/entities/daily_warm_up_answer_result_entity.dart';
part 'domain/repositories/i_daily_warm_up_repository.dart';
part 'domain/usecases/get_daily_warm_up_usecase.dart';

//* Presentation Layer - Helpers
part 'presentation/helpers/daily_warm_up_question_filter.dart';
part 'presentation/helpers/daily_warm_up_question_evaluator.dart';
part 'presentation/helpers/daily_warm_up_choice_answer_state_mapper.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/daily_warm_up_state.dart';
part 'presentation/cubits/daily_warm_up_cubit.dart';
part 'presentation/cubits/daily_warm_up_cubit_tracking.dart';

//* Presentation Layer - Pages
part 'presentation/pages/daily_warm_up_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/daily_warm_up_bottom_cta.dart';
part 'presentation/widgets/daily_warm_up_completion_step.dart';
part 'presentation/widgets/daily_warm_up_course_card.dart';
part 'presentation/widgets/daily_warm_up_entry_step.dart';
part 'presentation/widgets/daily_warm_up_progress_dots.dart';
part 'presentation/widgets/daily_warm_up_choice_answer_cards.dart';
part 'presentation/widgets/daily_warm_up_question_arrange_body.dart';
part 'presentation/widgets/daily_warm_up_question_body_helpers.dart';
part 'presentation/widgets/daily_warm_up_question_choice_body.dart';
part 'presentation/widgets/daily_warm_up_question_cues_body.dart';
part 'presentation/widgets/daily_warm_up_question_drag_drop_body.dart';
part 'presentation/widgets/daily_warm_up_question_step.dart';
part 'presentation/widgets/daily_warm_up_question_stress_body.dart';
part 'presentation/widgets/daily_warm_up_sentence_builder.dart';
part 'presentation/widgets/daily_warm_up_result_bottom_sheet.dart';
part 'presentation/widgets/daily_warm_up_result_explanation_content.dart';
part 'presentation/widgets/daily_warm_up_result_explanation_card.dart';
part 'presentation/widgets/daily_warm_up_result_summary.dart';

//* Parts for generated files
part 'daily_warm_up.freezed.dart';
part 'daily_warm_up.g.dart';
