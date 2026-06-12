library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:home_widget/home_widget.dart' as home_widget_plugin;
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/home_widget_model.dart';
part 'data/datasources/remote/home_widget_api.dart';
part 'data/datasources/local/home_widget_local_data_source.dart';
part 'data/services/home_widget_bridge.dart';
part 'data/repositories/home_widget_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/home_widget_constants.dart';
part 'domain/entities/home_widget_deeplink_target.dart';
part 'domain/entities/home_widget_entity.dart';
part 'domain/services/home_widget_payload_builder.dart';
part 'domain/services/home_widget_sync_trigger.dart';
part 'domain/repositories/i_home_widget_repository.dart';
part 'domain/usecases/sync_home_widgets_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/home_widget_state.dart';
part 'presentation/cubits/home_widget_cubit.dart';

//* Presentation Layer - Pages

//* Presentation Layer - Widgets

//* Parts for generated files
part 'home_widget.freezed.dart';
part 'home_widget.g.dart';
