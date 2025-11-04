library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'course.freezed.dart';
part 'course.g.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/course_lesson_local_data_source.dart';
part 'data/datasources/local/course_local_data_source.dart';
part 'data/datasources/remote/course_api.dart';
part 'data/datasources/remote/course_lesson_api.dart';
part 'data/models/course_model.dart';
part 'data/models/keypoint_model.dart';
part 'data/models/roadmap_model.dart';
part 'data/models/roadmap_node_model.dart';
part 'data/repositories/course_lesson_repository.dart';
part 'data/repositories/course_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/course_entity.dart';
part 'domain/entities/keypoint_entity.dart';
part 'domain/entities/roadmap_entity.dart';
part 'domain/entities/roadmap_node_entity.dart';
part 'domain/repositories/i_course_lesson_repository.dart';
part 'domain/repositories/i_course_repository.dart';
part 'domain/usecases/get_all_courses_usecase.dart';
part 'domain/usecases/get_all_lessons_usecase.dart';
part 'domain/usecases/get_course_usecase.dart';
part 'domain/usecases/get_lesson_usecase.dart';
part 'domain/usecases/get_roadmap_usecase.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/course/course_cubit.dart';
part 'presentation/cubits/course/course_state.dart';
part 'presentation/cubits/course_lesson/course_lesson_cubit.dart';
part 'presentation/cubits/course_lesson/course_lesson_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/course_page.dart';
part 'presentation/pages/course_roadmap_page.dart';
