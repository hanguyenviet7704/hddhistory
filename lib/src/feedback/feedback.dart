library;

//* Single project import
import 'package:meup/meup.dart';
import 'dart:ui' as ui;

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
part 'domain/entities/user_feedback_submission_entity.dart';
part 'domain/repositories/i_feedback_repository.dart';
part 'domain/usecases/get_user_feedbacks_usecase.dart';
part 'domain/usecases/update_user_feedback_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/feedback_state.dart';
part 'presentation/cubits/feedback_cubit.dart';

//* Presentation Layer - Widgets
part 'presentation/popup/feedback_complete_lesson_popup.dart';
part 'presentation/popup/feedback_incomplete_lesson_popup.dart';
part 'presentation/popup/feedback_before_you_go_popup.dart';
part 'presentation/widgets/feedback_popup_shell.dart';
part 'presentation/widgets/feedback_header.dart';
part 'presentation/widgets/feedback_rating_row.dart';
part 'presentation/widgets/feedback_reason_chip.dart';
part 'presentation/widgets/feedback_reason_list.dart';
part 'presentation/widgets/feedback_comment_field.dart';
part 'presentation/widgets/feedback_primary_button.dart';
part 'presentation/widgets/feedback_thank_you_body.dart';

//* Parts for generated files
part 'feedback.freezed.dart';
part 'feedback.g.dart';
