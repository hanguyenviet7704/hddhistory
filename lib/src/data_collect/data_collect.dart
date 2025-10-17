library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:retrofit/retrofit.dart';

part 'data/datasources/local/data_collect_local_data_source.dart';
part 'data/datasources/remote/data_collect_api.dart';
//* Parts - internal files using 'part of'
part 'data/models/user_collect_data_model.dart';
part 'data/repositories/data_collect_repository.dart';
//* Parts for generated files
part 'data_collect.freezed.dart';
part 'data_collect.g.dart';
part 'domain/entities/user_collect_data_entity.dart';
part 'domain/repositories/i_data_collect_repository.dart';
part 'domain/usecases/create_user_collect_data_usecase.dart';
part 'domain/usecases/delete_user_collect_data_usecase.dart';
part 'domain/usecases/get_all_user_collect_datas_usecase.dart';
part 'domain/usecases/get_user_collect_data_usecase.dart';
part 'domain/usecases/update_user_collect_data_usecase.dart';
//* State is shared between BLoC and Cubit
part 'presentation/cubits/data_collect_cubit.dart';
part 'presentation/cubits/data_collect_state.dart';
part 'presentation/pages/data_collect_motivation_step_page.dart';
//* Pages
part 'presentation/pages/data_collect_page.dart';
part 'presentation/pages/data_collect_summary_page.dart';
//* Widgets
part 'presentation/widgets/body/age_collect_body.dart';
part 'presentation/widgets/body/best_time_to_learn_body.dart';
part 'presentation/widgets/body/best_time_to_skilled_body.dart';
part 'presentation/widgets/body/choose_topic_body.dart';
part 'presentation/widgets/body/gender_collect_body.dart';
part 'presentation/widgets/body/learning_goal_body.dart';
part 'presentation/widgets/body/name_collect_body.dart';
part 'presentation/widgets/body/struggle_when_speaking_body.dart';
part 'presentation/widgets/item/age_option.dart';
part 'presentation/widgets/item/continue_button.dart';
part 'presentation/widgets/item/custom_radio.dart';
part 'presentation/widgets/item/gender_option.dart';
part 'presentation/widgets/item/onboarding_input.dart';
part 'presentation/widgets/item/progress_bar.dart';
part 'presentation/widgets/item/struggle_option.dart';
part 'presentation/widgets/item/this_describe_you_option.dart';
part 'presentation/widgets/item/topic_option.dart';
