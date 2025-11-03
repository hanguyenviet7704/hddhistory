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
part 'data/models/course_model.dart';
part 'data/models/skillset_model.dart';
part 'data/datasources/remote/home_api.dart';
part 'data/datasources/local/home_local_data_source.dart';
part 'data/repositories/home_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/skillset_entity.dart';
part 'domain/repositories/i_home_repository.dart';
part 'domain/usecases/get_skillset_usecase.dart';
part 'domain/usecases/get_all_skillsets_usecase.dart';
part 'domain/usecases/create_skillset_usecase.dart';
part 'domain/usecases/update_skillset_usecase.dart';
part 'domain/usecases/delete_skillset_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/blocs/home_state.dart';
part 'presentation/cubits/home_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/home_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'home.freezed.dart';
part 'home.g.dart';
