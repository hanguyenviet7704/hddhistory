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
//* Data Layer - Models, Datasources, Repositories
part 'data/models/user_model.dart';
part 'data/repositories/profile_repository.dart';
part 'data/repositories/upload_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/upload_entity.dart';
part 'domain/entities/user_entity.dart';
part 'domain/repositories/i_profile_repository.dart';
part 'domain/repositories/i_upload_repository.dart';
part 'domain/usecases/create_user_usecase.dart';
part 'domain/usecases/delete_user_usecase.dart';
part 'domain/usecases/get_all_users_usecase.dart';
part 'domain/usecases/get_user_usecase.dart';
part 'domain/usecases/update_user_usecase.dart';
part 'domain/usecases/upload_file_usecase.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/profile/profile_cubit.dart';
part 'presentation/cubits/profile/profile_state.dart';
part 'presentation/cubits/upload/upload_cubit.dart';
part 'presentation/cubits/upload/upload_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/profile_page.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'profile.freezed.dart';
part 'profile.g.dart';
