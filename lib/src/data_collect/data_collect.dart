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
//* Pages
part 'presentation/pages/data_collect_motivation_step_page.dart';
part 'presentation/pages/data_collect_page.dart';
part 'presentation/pages/data_collect_summary_page.dart';
part 'presentation/pages/notification_request_page.dart';
//* Widgets
part 'presentation/widgets/body/01_name_collect_body.dart';
part 'presentation/widgets/body/02_age_collect_body.dart';
part 'presentation/widgets/body/03_gender_collect_body.dart';
part 'presentation/widgets/body/04_learning_goal_body.dart';
part 'presentation/widgets/body/05_skillset_want_to_master_body.dart';
part 'presentation/widgets/body/06_learning_strugger_body.dart';
part 'presentation/widgets/body/07_how_to_learn_body.dart';
part 'presentation/widgets/body/08_daily_learning_goal_body.dart';
part 'presentation/widgets/body/09_comfortable_learning_time_body.dart';
part 'presentation/widgets/item/age_option.dart';
part 'presentation/widgets/item/analysis_state.dart';
part 'presentation/widgets/item/animated_summary_progress_bar.dart';
part 'presentation/widgets/item/continue_button.dart';
part 'presentation/widgets/item/custom_radio.dart';
part 'presentation/widgets/item/data_collect_option_tile.dart';
part 'presentation/widgets/item/data_collect_section_header.dart';
part 'presentation/widgets/item/gender_option.dart';
part 'presentation/widgets/item/onboarding_input.dart';
part 'presentation/widgets/item/progress_bar.dart';
part 'presentation/widgets/item/start_journey_button.dart';
part 'presentation/widgets/item/struggle_option.dart';
part 'presentation/widgets/item/summary_progress_bar.dart';
part 'presentation/widgets/item/this_describe_you_option.dart';
part 'presentation/widgets/item/topic_option.dart';
part 'presentation/widgets/item/user_data_state.dart';
part 'presentation/widgets/item/motivation_step_content.dart';
