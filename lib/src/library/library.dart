library;

//* Single project import
import 'package:meup/meup.dart';

//* Dart imports
import 'dart:math' as math;
import 'dart:ui' as ui;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Domain Layer - Entities
part 'domain/entities/saved_card_entity.dart';
part 'domain/entities/saved_course_filter.dart';

//* Data Layer - Models, Datasource, Repository impl
part 'data/models/saved_card_model.dart';
part 'data/datasources/remote/saved_api.dart';
part 'data/repositories/saved_repository.dart';

//* Domain Layer - Repository interface, Use cases
part 'domain/repositories/i_saved_repository.dart';
part 'domain/usecases/get_saved_courses_usecase.dart';
part 'domain/usecases/get_saved_course_ids_usecase.dart';
part 'domain/usecases/toggle_saved_course_usecase.dart';
part 'domain/usecases/get_saved_cards_usecase.dart';
part 'domain/usecases/get_saved_card_ids_usecase.dart';
part 'domain/usecases/toggle_saved_card_usecase.dart';

//* Presentation Layer - Cubits + States
part 'presentation/cubits/saved/saved_state.dart';
part 'presentation/cubits/saved/saved_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/library_history_page.dart';
part 'presentation/pages/library_page.dart';
part 'presentation/pages/saved_cards_page.dart';
part 'presentation/pages/saved_courses_page.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/course_options_sheet.dart';
part 'presentation/widgets/library_course_card.dart';
part 'presentation/widgets/saved_card_actions.dart';
part 'presentation/widgets/saved_card_detail_overlay.dart';
part 'presentation/widgets/saved_cards_deck.dart';
part 'presentation/widgets/saved_quote_card.dart';
part 'presentation/widgets/saved_share.dart';

//* Parts for generated files
part 'library.freezed.dart';
part 'library.g.dart';
