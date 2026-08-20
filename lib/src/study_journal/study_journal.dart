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
part 'data/models/study_journal_month_model.dart';
part 'data/models/study_journal_day_model.dart';
part 'data/datasources/remote/study_journal_api.dart';
part 'data/repositories/study_journal_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/study_journal_month_entity.dart';
part 'domain/entities/study_journal_day_entity.dart';
part 'domain/repositories/i_study_journal_repository.dart';
part 'domain/usecases/get_study_journal_month_usecase.dart';
part 'domain/usecases/get_study_journal_day_usecase.dart';

//* Presentation Layer - Cubit
part 'presentation/cubits/study_journal_state.dart';
part 'presentation/cubits/study_journal_cubit.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/study_journal_calendar.dart';
part 'presentation/widgets/study_journal_day_sheet.dart';

//* Parts for generated files
part 'study_journal.freezed.dart';
part 'study_journal.g.dart';
