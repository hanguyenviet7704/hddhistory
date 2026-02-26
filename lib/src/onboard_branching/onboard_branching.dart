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
part 'data/models/onboarding_content_type_model.dart';
part 'data/models/onboarding_scenario_branching_model.dart';
part 'data/models/onboarding_scenario_scene_model.dart';
part 'data/models/onboarding_scenario_content_item_model.dart';
part 'data/models/onboarding_scenario_activation_model.dart';
part 'data/models/onboarding_scenario_activation_content_model.dart';
part 'data/models/onboarding_scenario_branch_model.dart';
part 'data/models/onboarding_scenario_branch_option_model.dart';
part 'data/models/onboarding_scenario_fixed_model.dart';
part 'data/models/onboarding_scenario_person_admire_model.dart';
part 'data/models/onboarding_scenario_person_option_model.dart';
part 'data/datasources/remote/onboard_branching_api.dart';
part 'data/datasources/local/onboard_branching_local_data_source.dart';
part 'data/repositories/onboard_branching_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/onboarding_scenario_branching_entity.dart';
part 'domain/repositories/i_onboard_branching_repository.dart';
part 'domain/usecases/get_onboarding_scenario_branching_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/onboard_branching_state.dart';
part 'presentation/cubits/onboard_branching_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/onboard_branching_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'onboard_branching.freezed.dart';
part 'onboard_branching.g.dart';
