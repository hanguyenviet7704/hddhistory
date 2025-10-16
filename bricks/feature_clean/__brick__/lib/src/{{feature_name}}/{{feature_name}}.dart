library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/models/{{#snakeCase}}{{entity_name}}{{/snakeCase}}_model.dart';
part 'data/datasources/remote/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_api.dart';
part 'data/datasources/local/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_local_data_source.dart';
part 'data/repositories/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/{{#snakeCase}}{{entity_name}}{{/snakeCase}}_entity.dart';
part 'domain/repositories/i_{{#snakeCase}}{{feature_name}}{{/snakeCase}}_repository.dart';
part 'domain/usecases/get_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
part 'domain/usecases/get_all_{{#snakeCase}}{{entity_name}}{{/snakeCase}}s_usecase.dart';
part 'domain/usecases/create_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
part 'domain/usecases/update_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
part 'domain/usecases/delete_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_state.dart';
{{#use_bloc}}part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_bloc.dart';
part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_event.dart';{{/use_bloc}}{{^use_bloc}}part 'presentation/cubits/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_cubit.dart';{{/use_bloc}}

//* Presentation Layer - Pages
part 'presentation/pages/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part '{{#snakeCase}}{{feature_name}}{{/snakeCase}}.freezed.dart';
part '{{#snakeCase}}{{feature_name}}{{/snakeCase}}.g.dart';
