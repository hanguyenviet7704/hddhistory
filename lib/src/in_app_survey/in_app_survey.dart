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
part 'data/models/in_app_survey_question_model.dart';
part 'data/models/in_app_survey_emoji_model.dart';
part 'data/models/in_app_survey_option_model.dart';
part 'data/models/in_app_survey_closed_question_model.dart';
part 'data/models/in_app_survey_branch_model.dart';
part 'data/models/in_app_survey_config_model.dart';
part 'data/datasources/remote/in_app_survey_api.dart';
part 'data/datasources/local/in_app_survey_local_data_source.dart';
part 'data/repositories/in_app_survey_repository.dart';


//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/in_app_survey_question_entity.dart';
part 'domain/entities/in_app_survey_emoji_entity.dart';
part 'domain/entities/in_app_survey_option_entity.dart';
part 'domain/entities/in_app_survey_closed_question_entity.dart';
part 'domain/entities/in_app_survey_branch_entity.dart';
part 'domain/entities/in_app_survey_config_entity.dart';
part 'domain/entities/in_app_survey_response_entity.dart';
part 'domain/repositories/i_in_app_survey_repository.dart';
part 'domain/usecases/get_in_app_survey_config_usecase.dart';
part 'domain/usecases/create_in_app_survey_config_usecase.dart';


//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/in_app_survey_state.dart';
part 'presentation/cubits/in_app_survey_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/in_app_survey_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'in_app_survey.freezed.dart';
part 'in_app_survey.g.dart';

