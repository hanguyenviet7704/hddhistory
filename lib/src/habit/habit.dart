library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/habit_model.dart';
part 'data/models/user_habit_model.dart';
part 'data/models/user_habit_summary_model.dart';
part 'data/models/habit_checkin_model.dart';
part 'data/models/reanchor_reason_model.dart';
part 'data/datasources/remote/habit_api.dart';
part 'data/repositories/habit_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/habit_entity.dart';
part 'domain/entities/user_habit_entity.dart';
part 'domain/entities/user_habit_summary_entity.dart';
part 'domain/entities/habit_checkin_entity.dart';
part 'domain/entities/reanchor_reason_entity.dart';
part 'domain/repositories/i_habit_repository.dart';
part 'domain/usecases/get_habits_usecase.dart';
part 'domain/usecases/get_user_habits_usecase.dart';
part 'domain/usecases/get_user_habits_summary_usecase.dart';
part 'domain/usecases/adopt_habit_usecase.dart';
part 'domain/usecases/update_user_habit_usecase.dart';
part 'domain/usecases/remove_user_habit_usecase.dart';
part 'domain/usecases/check_in_user_habit_usecase.dart';
part 'domain/usecases/get_habit_checkins_usecase.dart';
part 'domain/usecases/get_reanchor_reasons_usecase.dart';
part 'domain/usecases/get_habit_config_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/habit_qa_flags.dart';
part 'presentation/cubits/habit_state.dart';
part 'presentation/cubits/habit_cubit.dart';
part 'presentation/cubits/habit_reminder_scheduler.dart';

//* Presentation Layer - Pages
part 'presentation/pages/habit_page.dart';
part 'presentation/pages/adopt_habit_page.dart';
part 'presentation/pages/daily_check_in_page.dart';
part 'presentation/pages/habit_summary_page.dart';
part 'presentation/pages/upgrade_habit_page.dart';
part 'presentation/pages/manage_slots_page.dart';
part 'presentation/pages/habit_detail_page.dart';
part 'presentation/pages/reanchor_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/habit_added_popup.dart';
part 'presentation/widgets/check_in_diary_sheet.dart';
part 'presentation/widgets/edit_habit_sheet.dart';
part 'presentation/widgets/slot_full_upgrade_sheet.dart';
part 'presentation/widgets/habit_week_grid.dart';
part 'presentation/widgets/habit_task_row.dart';
part 'presentation/widgets/habit_empty_state.dart';
part 'presentation/widgets/habit_domain_icon.dart';
part 'presentation/widgets/habit_switch.dart';
part 'presentation/widgets/home_habit_reminder_card.dart';

//* Parts for generated files
part 'habit.freezed.dart';
part 'habit.g.dart';
