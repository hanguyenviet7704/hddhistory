library;

//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/spaced_review_today_model.dart';
part 'data/datasources/remote/spaced_review_api.dart';
part 'data/repositories/spaced_review_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/spaced_review_today_entity.dart';
part 'domain/repositories/i_spaced_review_repository.dart';
part 'domain/usecases/get_spaced_review_today_usecase.dart';
part 'domain/usecases/submit_spaced_review_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/spaced_review_state.dart';
part 'presentation/cubits/spaced_review_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/spaced_review_question_page.dart';
part 'presentation/pages/spaced_review_completion_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/spaced_review_home_card.dart';

//* Parts for generated files
part 'spaced_review.freezed.dart';
part 'spaced_review.g.dart';
