library;

//* Dart imports
// Prefixed: a package in the meup export graph shadows dart:ui's Path (breaks
// Path.addRRect/computeMetrics), so reference ui.Path / ui.ImageFilter directly.
import 'dart:ui' as ui;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Domain Layer - Entities
part 'domain/entities/study_theme_preset.dart';

//* Data Layer - remote catalogue (model, datasource, repository impl) + the
//* bundled offline-fallback catalog
part 'data/models/study_theme_preset_model.dart';
part 'data/datasources/remote/study_theme_api.dart';
part 'data/preset_catalog.dart';
part 'data/repositories/study_theme_repository.dart';

//* Domain Layer - Repository interface, Use case
part 'domain/repositories/i_study_theme_repository.dart';
part 'domain/usecases/get_study_themes_usecase.dart';

//* Presentation Layer - Cubit + State
part 'presentation/cubits/study_theme_state.dart';
part 'presentation/cubits/study_theme_cubit.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/themed_background.dart';
part 'presentation/widgets/themed_glass_card.dart';
part 'presentation/widgets/change_background_button.dart';
part 'presentation/widgets/change_background_sheet.dart';

//* Parts for generated files
part 'study_theme.freezed.dart';
part 'study_theme.g.dart';
