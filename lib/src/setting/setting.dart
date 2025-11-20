library;

//* Package imports
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';

//* Data Layer - Models, Datasources, Repositories

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/setting_entity.dart';
part 'domain/repositories/i_setting_repository.dart';
part 'domain/usecases/get_setting_usecase.dart';
part 'presentation/cubits/setting_cubit.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/setting_state.dart';
part 'presentation/pages/change_language_page.dart';
//* Presentation Layer - Pages
part 'presentation/pages/setting_page.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/setting/setting_profile_card.dart';
part 'presentation/widgets/setting/setting_section_card.dart';
//* Parts for generated files
part 'setting.freezed.dart';
part 'setting.g.dart';
