library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Parts - internal files using 'part of'
part 'data/datasources/local/onboard_local_data_source.dart';
part 'data/datasources/remote/onboard_api.dart';
part 'data/models/onboard_copy_model.dart';
part 'data/models/onboard_intro_model.dart';
part 'data/models/onboard_model.dart';
part 'data/models/onboard_motivation.dart';
part 'data/models/onboard_option_model.dart';
part 'data/models/onboard_path_model.dart';
part 'data/models/onboard_symptom_model.dart';
part 'data/repositories/onboard_repository.dart';
part 'domain/entities/onboard_copy_entity.dart';
part 'domain/entities/onboard_entity.dart';
part 'domain/entities/onboard_intro_entity.dart';
part 'domain/entities/onboard_motivation_entity.dart';
part 'domain/entities/onboard_option_entity.dart';
part 'domain/entities/onboard_path_entity.dart';
part 'domain/entities/onboard_symptom_entity.dart';
part 'domain/repositories/i_onboard_repository.dart';
part 'domain/usecases/get_all_onboards_usecase.dart';
part 'domain/usecases/get_user_by_device_id_usecase.dart';
//* Parts for generated files
part 'onboard.freezed.dart';
part 'onboard.g.dart';
//* State is shared between BLoC and Cubit
part 'presentation/cubits/intro/intro_cubit.dart';
part 'presentation/cubits/intro/intro_state.dart';
part 'presentation/cubits/onboard/onboard_cubit.dart';
part 'presentation/cubits/onboard/onboard_state.dart';
//* Pages
part 'presentation/pages/splash_page.dart';
//* Widgets
part 'presentation/widgets/continue_button_widget.dart';
