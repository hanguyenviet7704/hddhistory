library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_progress_model.dart';
part 'data/models/lesson_result_model.dart';
part 'data/models/keypoint_result_model.dart';
part 'data/models/exercise_result_model.dart';
part 'data/datasources/remote/user_progress_api.dart';
part 'data/datasources/local/progress_local_data_source.dart';
part 'data/repositories/progress_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/user_progress_entity.dart';
part 'domain/entities/lesson_result_entity.dart';
part 'domain/entities/keypoint_result_entity.dart';
part 'domain/entities/exercise_result_entity.dart';
part 'domain/repositories/i_progress_repository.dart';
part 'domain/usecases/get_all_user_progresss_usecase.dart';
part 'domain/usecases/get_user_progress_lesson_usecase.dart';
part 'domain/usecases/get_user_progress_keypoint_usecase.dart';
part 'domain/usecases/get_user_progress_exercise_usecase.dart';
part 'domain/usecases/get_user_progress_my_courses_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/progress_state.dart';
part 'presentation/cubits/progress_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/progress_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'progress.freezed.dart';
part 'progress.g.dart';
