library;

//* Dart imports
import 'dart:ui' as ui;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart' as df;
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/week_recap_model.dart';
part 'data/datasources/remote/week_recap_api.dart';
part 'data/repositories/week_recap_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/week_recap_entity.dart';
part 'domain/repositories/i_week_recap_repository.dart';
part 'domain/usecases/get_current_week_recap_usecase.dart';
part 'domain/usecases/get_week_recap_archive_usecase.dart';
part 'domain/usecases/get_week_recap_usecase.dart';
part 'domain/usecases/mark_week_recap_interacted_usecase.dart';

//* Presentation Layer - Cubit
part 'presentation/cubits/week_recap_state.dart';
part 'presentation/cubits/week_recap_cubit.dart';
// TEMP-DEBUG: remove with the seed file when design review is done.
part 'presentation/cubits/week_recap_debug_seed.dart';

//* Presentation Layer - Pages
part 'presentation/pages/week_recap_page.dart';
part 'presentation/pages/week_recap_archive_page.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/week_recap_poster.dart';
part 'presentation/widgets/week_recap_poster_slots.dart';
part 'presentation/widgets/week_recap_calendar.dart';
part 'presentation/widgets/week_recap_banner.dart';
part 'presentation/widgets/week_recap_monday_popup.dart';
part 'presentation/widgets/week_recap_locked_popup.dart';
part 'presentation/widgets/week_recap_popup_host.dart';
part 'presentation/widgets/week_recap_share_bar.dart';

//* Parts for generated files
part 'week_recap.freezed.dart';
part 'week_recap.g.dart';
