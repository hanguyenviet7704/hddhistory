library;

//* Single project import
// Also re-exports dart:async (Timer), modal_bottom_sheet, file_picker and
// flutter_bloc — importing those directly here is flagged as redundant.
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Domain Layer - Entities
part 'domain/entities/learning_import_job_entity.dart';
part 'domain/entities/user_lesson_entity.dart';
part 'domain/entities/import_quota_entity.dart';

//* Data Layer - Models, Datasource, Repository impl
part 'data/models/learning_import_job_model.dart';
part 'data/models/user_lesson_model.dart';
part 'data/models/import_quota_model.dart';
part 'data/datasources/remote/learning_import_api.dart';
part 'data/repositories/learning_import_repository.dart';

//* Domain Layer - Repository interface, Use cases
part 'domain/repositories/i_learning_import_repository.dart';
part 'domain/usecases/create_learning_import_usecase.dart';
part 'domain/usecases/get_learning_import_job_usecase.dart';
part 'domain/usecases/get_import_quota_usecase.dart';
part 'domain/usecases/get_user_lessons_usecase.dart';
part 'domain/usecases/get_user_lesson_usecase.dart';
part 'domain/usecases/update_user_lesson_progress_usecase.dart';
part 'domain/usecases/delete_user_lesson_usecase.dart';

//* Presentation Layer - Cubits + States
part 'presentation/cubits/learning_import_state.dart';
part 'presentation/cubits/learning_import_cubit.dart';
part 'presentation/cubits/user_lesson_state.dart';
part 'presentation/cubits/user_lesson_cubit.dart';

//* Presentation Layer - Pages + Sheets
part 'presentation/pages/my_lessons_page.dart';
part 'presentation/pages/lesson_reader_page.dart';
part 'presentation/sheets/import_source_sheet.dart';

//* Parts for generated files
part 'learning_import.freezed.dart';
part 'learning_import.g.dart';
