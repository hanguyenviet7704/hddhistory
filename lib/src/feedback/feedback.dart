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
part 'data/models/user_feedback_complete_model.dart';
part 'data/models/user_feedback_incomplete_model.dart';
part 'data/models/user_feedback_model.dart';
part 'data/datasources/remote/feedback_api.dart';
part 'data/datasources/local/feedback_local_data_source.dart';
part 'data/repositories/feedback_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/user_feedback_complete_entity.dart';
part 'domain/entities/user_feedback_incomplete_entity.dart';
part 'domain/entities/user_feedback_entity.dart';
part 'domain/repositories/i_feedback_repository.dart';
part 'domain/usecases/get_user_feedbacks_usecase.dart';
part 'domain/usecases/update_user_feedback_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/feedback_state.dart';
part 'presentation/cubits/feedback_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/feedback_page.dart';

//* Parts for generated files
part 'feedback.freezed.dart';
part 'feedback.g.dart';

