library;

//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/onboarding_welcome_config_model.dart';
part 'data/models/onboarding_name_config_model.dart';
part 'data/models/onboarding_age_config_model.dart';
part 'data/models/onboarding_paths_config_model.dart';
part 'data/models/onboarding_brain_config_model.dart';
part 'data/models/onboarding_habit_config_model.dart';
part 'data/models/onboarding_notif_config_model.dart';
part 'data/models/onboarding_pick_config_model.dart';
part 'data/models/onboarding_theme_config_model.dart';
part 'data/models/onboarding_desire_config_model.dart';
part 'data/models/onboarding_how_config_model.dart';
part 'data/models/onboarding_reminder_config_model.dart';
part 'data/models/onboarding_loading_config_model.dart';
part 'data/models/onboarding_content_config_model.dart';
part 'data/models/onboarding_taxonomy_model.dart';
part 'data/models/onboarding_recommendation_model.dart';
part 'data/datasources/remote/onboarding_api.dart';
part 'data/datasources/local/onboarding_local_data_source.dart';
part 'data/repositories/onboarding_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/onboarding_welcome_config_entity.dart';
part 'domain/entities/onboarding_name_config_entity.dart';
part 'domain/entities/onboarding_age_config_entity.dart';
part 'domain/entities/onboarding_paths_config_entity.dart';
part 'domain/entities/onboarding_brain_config_entity.dart';
part 'domain/entities/onboarding_habit_config_entity.dart';
part 'domain/entities/onboarding_notif_config_entity.dart';
part 'domain/entities/onboarding_pick_config_entity.dart';
part 'domain/entities/onboarding_theme_config_entity.dart';
part 'domain/entities/onboarding_desire_config_entity.dart';
part 'domain/entities/onboarding_how_config_entity.dart';
part 'domain/entities/onboarding_reminder_config_entity.dart';
part 'domain/entities/onboarding_loading_config_entity.dart';
part 'domain/entities/onboarding_content_config_entity.dart';
part 'domain/entities/onboarding_taxonomy_entity.dart';
part 'domain/entities/onboarding_recommendation_entity.dart';
part 'domain/repositories/i_onboarding_repository.dart';
part 'domain/usecases/get_onboarding_content_config_usecase.dart';
part 'domain/usecases/get_onboarding_taxonomy_usecase.dart';
part 'domain/usecases/submit_onboarding_answers_usecase.dart';

//* Parts for generated files
part 'onboarding.freezed.dart';
part 'onboarding.g.dart';
