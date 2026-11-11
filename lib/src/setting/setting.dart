library;

//* Package imports
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:hddhistory/hddhistory.dart';

//* Data Layer - Models, Datasources, Repositories

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/setting_entity.dart';
part 'domain/repositories/i_setting_repository.dart';
part 'domain/usecases/get_setting_usecase.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/notification/notification_cubit.dart';
part 'presentation/cubits/notification/notification_state.dart';
part 'presentation/cubits/setting/setting_cubit.dart';
part 'presentation/cubits/setting/setting_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/setting_page.dart';
//* Presentation Layer - Widgets
part 'presentation/widgets/setting/setting_preminum_card.dart';
part 'presentation/widgets/setting/setting_section_card.dart';
//* Parts for generated files
part 'setting.freezed.dart';
part 'setting.g.dart';
