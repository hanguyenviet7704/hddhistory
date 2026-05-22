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
part 'data/models/daily_warm_up_model.dart';
part 'data/datasources/remote/daily_warm_up_api.dart';
part 'data/datasources/local/daily_warm_up_local_data_source.dart';
part 'data/repositories/daily_warm_up_repository.dart';


//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/daily_warm_up_entity.dart';
part 'domain/repositories/i_daily_warm_up_repository.dart';
part 'domain/usecases/get_daily_warm_up_usecase.dart';


//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/daily_warm_up_state.dart';
part 'presentation/cubits/daily_warm_up_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/daily_warm_up_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'daily_warm_up.freezed.dart';
part 'daily_warm_up.g.dart';

