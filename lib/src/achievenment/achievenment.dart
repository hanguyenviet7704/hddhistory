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
part 'data/models/achievenment_response_model.dart';
part 'data/models/course_level_progress.dart';
part 'data/datasources/local/achievenment_local_data_source.dart';
part 'data/datasources/remote/achievenment_api.dart';
part 'data/repositories/achievenment_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/achievenment_response_entity.dart';
part 'domain/entities/course_level_progress_entity.dart';
part 'domain/repositories/i_achievenment_repository.dart';
part 'domain/usecases/get_achievenment_response_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/blocs/achievenment_state.dart';
part 'presentation/cubits/achievenment_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/achievenment_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'achievenment.freezed.dart';
part 'achievenment.g.dart';

