library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

part 'data/datasources/local/achievenment_progress_local_data_source.dart';
part 'data/datasources/local/progress_local_data_source.dart';
part 'data/datasources/remote/achievenment_progress_api.dart';
part 'data/datasources/remote/content_request_api.dart';
part 'data/datasources/remote/user_progress_api.dart';
part 'data/models/completed_level_model.dart';
part 'data/models/exercise_result_model.dart';
part 'data/models/keypoint_result_model.dart';
part 'data/models/lesson_result_model.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_progress_model.dart';
part 'data/repositories/achievenment_progress_repository.dart';
part 'data/repositories/content_request_repository.dart';
part 'data/repositories/progress_repository.dart';
part 'domain/entities/completed_level_entity.dart';
part 'domain/entities/exercise_result_entity.dart';
part 'domain/entities/keypoint_result_entity.dart';
part 'domain/entities/lesson_result_entity.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/user_progress_entity.dart';
part 'domain/repositories/i_achievenment_progress_repository.dart';
part 'domain/repositories/i_content_request_repository.dart';
part 'domain/repositories/i_progress_repository.dart';
part 'domain/usecases/create_completed_level_additional_content_request_usecase.dart';
part 'domain/usecases/get_all_achievenment_responses_usecase.dart';
part 'domain/usecases/get_cached_achievenment_responses_usecase.dart';
part 'domain/usecases/get_all_user_progresss_usecase.dart';
part 'domain/usecases/get_course_level_progress_usecase.dart';
part 'domain/usecases/get_user_progress_exercise_usecase.dart';
part 'domain/usecases/get_user_progress_keypoint_usecase.dart';
part 'domain/usecases/get_user_progress_lesson_usecase.dart';
part 'domain/usecases/get_user_progress_my_courses_usecase.dart';
part 'domain/usecases/update_user_progress_exercise_usecase.dart';
part 'domain/usecases/update_user_progress_keypoint_usecase.dart';
part 'domain/usecases/update_user_progress_lesson_usecase.dart';
part 'presentation/cubits/achievenment_progress/achievenment_progress_cubit.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/achievenment_progress/achievenment_progress_state.dart';
part 'presentation/cubits/progress/progress_cubit_completed_level_content_request_mixin.dart';
part 'presentation/cubits/progress/progress_cubit.dart';
part 'presentation/cubits/progress/progress_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/progress_page.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'progress.freezed.dart';
part 'progress.g.dart';
