library;

//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:lottie/lottie.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/warm_up_for_course_model.dart';
part 'data/models/warm_up_previous_lesson_model.dart';
part 'data/datasources/remote/warm_up_api.dart';
part 'data/repositories/warm_up_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/warm_up_for_course_entity.dart';
part 'domain/entities/warm_up_previous_lesson_entity.dart';
part 'domain/repositories/i_warm_up_repository.dart';
part 'domain/usecases/check_warm_up_for_course_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/warm_up_state.dart';
part 'presentation/cubits/warm_up_cubit.dart';

//* Presentation Layer - Helpers
part 'presentation/helpers/warm_up_tracking.dart';

//* Presentation Layer - Pages
part 'presentation/pages/warm_up_intro_page.dart';
part 'presentation/pages/warm_up_question_page.dart';
part 'presentation/pages/warm_up_completion_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/warm_up_next_lesson_card.dart';

//* Parts for generated files
part 'warm_up.freezed.dart';
part 'warm_up.g.dart';
