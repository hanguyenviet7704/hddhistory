library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

part 'data/datasources/local/profile_local_data_source.dart';
part 'data/datasources/remote/profile_api.dart';
part 'data/datasources/remote/upload_api.dart';
part 'data/models/upload_model.dart';
part 'data/models/user_last_action_model.dart';
//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_model.dart';
part 'data/repositories/profile_repository.dart';
part 'data/repositories/upload_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/upload_entity.dart';
part 'domain/entities/user_entity.dart';
part 'domain/entities/user_last_action_entity.dart';
part 'domain/repositories/i_profile_repository.dart';
part 'domain/repositories/i_upload_repository.dart';
part 'domain/usecases/get_user_usecase.dart';
part 'domain/usecases/update_user_usecase.dart';
part 'domain/usecases/upload_file_usecase.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/profile/profile_cubit.dart';
part 'presentation/cubits/profile/profile_state.dart';
part 'presentation/cubits/upload/upload_cubit.dart';
part 'presentation/cubits/upload/upload_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/profile_info_page.dart';
part 'presentation/pages/profile_page.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/profile_header.dart';
part 'presentation/widgets/profile_field.dart';
part 'presentation/widgets/profile_delete_button.dart';
part 'presentation/widgets/profile_delete_dialog.dart';
part 'presentation/widgets/user_achievement_card.dart';
part 'presentation/widgets/user_achievement_course_item.dart';
part 'presentation/widgets/user_achievement_progress_bar.dart';
part 'presentation/widgets/user_achievement_list.dart';

//* Parts for generated files
part 'profile.freezed.dart';
part 'profile.g.dart';
