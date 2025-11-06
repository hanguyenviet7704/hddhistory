library;

//* Package imports
import 'package:darq/darq.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/home_local_data_source.dart';
part 'data/datasources/remote/skillset_api.dart';
part 'data/models/skillset_model.dart';
part 'data/repositories/home_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/skillset_entity.dart';
part 'domain/repositories/i_home_repository.dart';
part 'domain/usecases/get_all_skillsets_usecase.dart';
part 'domain/usecases/get_skillset_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'home.freezed.dart';
part 'home.g.dart';
part 'presentation/cubits/home_cubit.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/home_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/home_page.dart';
//* Presentation Layer - Custom Widgets
part 'presentation/widgets/course_card.dart';
part 'presentation/widgets/home_header.dart';
part 'presentation/widgets/section_header.dart';
part 'presentation/widgets/skillset_card.dart';
