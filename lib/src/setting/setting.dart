library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';


//* Data Layer - Models, Datasources, Repositories


//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/setting_entity.dart';
part 'domain/repositories/i_setting_repository.dart';
part 'domain/usecases/get_setting_usecase.dart';


//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/blocs/setting_state.dart';
part 'presentation/cubits/setting_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/setting_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'setting.freezed.dart';
part 'setting.g.dart';

