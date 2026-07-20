library;

//* Dart imports
import 'dart:ui' show ImageFilter;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

//* Domain Layer - Entities
part 'domain/entities/study_theme_preset.dart';

//* Data Layer - sample catalog (official data from lynci later)
part 'data/preset_catalog.dart';

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
