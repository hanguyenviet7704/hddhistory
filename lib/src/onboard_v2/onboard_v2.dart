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
part 'data/models/onboard_v2_model.dart';
part 'data/datasources/remote/onboard_v2_api.dart';
part 'data/datasources/local/onboard_v2_local_data_source.dart';
part 'data/repositories/onboard_v2_repository.dart';


//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/onboard_v2_entity.dart';
part 'domain/repositories/i_onboard_v2_repository.dart';
part 'domain/usecases/get_onboard_v2_usecase.dart';
part 'domain/usecases/get_all_onboard_v2s_usecase.dart';


//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/onboard_v2_state.dart';
part 'presentation/cubits/onboard_v2_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/onboard_v2_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'onboard_v2.freezed.dart';
part 'onboard_v2.g.dart';

