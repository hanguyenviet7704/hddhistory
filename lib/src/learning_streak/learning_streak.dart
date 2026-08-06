library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:lottie/lottie.dart';
import 'package:retrofit/retrofit.dart';
// Prefixed: rive 0.14 (rive_native) exports `File` and `Factory`, which would
// otherwise collide with dart:io / Flutter foundation via the meup barrel.
import 'package:rive/rive.dart' as rive;

//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_learning_streak_model.dart';
part 'data/models/streak_popup_config_model.dart';
part 'data/datasources/remote/learning_streak_api.dart';
part 'data/datasources/local/learning_streak_local_data_source.dart';
part 'data/repositories/learning_streak_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/user_learning_streak_entity.dart';
part 'domain/entities/learning_streak_fetch_entity.dart';
part 'domain/entities/streak_popup_config_entity.dart';
part 'domain/repositories/i_learning_streak_repository.dart';
part 'domain/usecases/get_user_learning_streak_usecase.dart';
part 'domain/usecases/get_streak_popup_config_usecase.dart';
part 'domain/usecases/check_in_streak_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/learning_streak_state.dart';
part 'presentation/cubits/learning_streak_cubit.dart';
part 'presentation/cubits/learning_streak_request_result.dart';
part 'presentation/helpers/learning_streak_completion_gate.dart';
part 'presentation/helpers/learning_streak_modal_guard.dart';
part 'presentation/helpers/streak_day.dart';
part 'presentation/helpers/streak_popup_scheduler.dart';

//* Presentation Layer - Pages
part 'presentation/pages/learning_streak_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/streak_home_chip.dart';
part 'presentation/widgets/streak_home_popup_content.dart';
part 'presentation/widgets/streak_success_overlay_content.dart';
part 'presentation/widgets/streak_week_bar.dart';
part 'presentation/widgets/streak_toast_content.dart';
part 'presentation/widgets/streak_popup_host.dart';

//* Parts for generated files
part 'learning_streak.freezed.dart';
part 'learning_streak.g.dart';
