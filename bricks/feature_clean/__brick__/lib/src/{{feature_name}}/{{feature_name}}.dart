library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
{{#has_remote_datasource}}import 'package:dio/dio.dart';
{{/has_remote_datasource}}{{#needs_fpdart}}import 'package:fpdart/fpdart.dart' hide State;
{{/needs_fpdart}}{{#needs_freezed}}import 'package:freezed_annotation/freezed_annotation.dart';
{{/needs_freezed}}{{#needs_injectable}}import 'package:injectable/injectable.dart';
{{/needs_injectable}}{{#needs_retrofit}}import 'package:retrofit/retrofit.dart';
{{/needs_retrofit}}

//* Data Layer - Models, Datasources, Repositories
{{#include_data_layer}}part 'data/models/{{#snakeCase}}{{entity_name}}{{/snakeCase}}_model.dart';
{{#has_remote_datasource}}part 'data/datasources/remote/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_api.dart';
{{/has_remote_datasource}}{{#has_local_cache}}part 'data/datasources/local/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_local_data_source.dart';
{{/has_local_cache}}part 'data/repositories/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_repository.dart';
{{/include_data_layer}}

//* Domain Layer - Entities, Repositories, Use Cases
{{#include_domain_layer}}part 'domain/entities/{{#snakeCase}}{{entity_name}}{{/snakeCase}}_entity.dart';
part 'domain/repositories/i_{{#snakeCase}}{{feature_name}}{{/snakeCase}}_repository.dart';
{{#has_detail}}part 'domain/usecases/get_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
{{/has_detail}}{{#has_list}}part 'domain/usecases/get_all_{{#snakeCase}}{{entity_name}}{{/snakeCase}}s_usecase.dart';
{{/has_list}}{{#has_create}}part 'domain/usecases/create_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
{{/has_create}}{{#has_update}}part 'domain/usecases/update_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
{{/has_update}}{{#has_delete}}part 'domain/usecases/delete_{{#snakeCase}}{{entity_name}}{{/snakeCase}}_usecase.dart';
{{/has_delete}}{{/include_domain_layer}}

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
{{#include_state_management}}part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_state.dart';
{{#use_bloc}}part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_bloc.dart';
part 'presentation/blocs/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_event.dart';{{/use_bloc}}{{^use_bloc}}part 'presentation/cubits/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_cubit.dart';{{/use_bloc}}{{/include_state_management}}

//* Presentation Layer - Pages
part 'presentation/pages/{{#snakeCase}}{{feature_name}}{{/snakeCase}}_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
{{#needs_freezed}}part '{{#snakeCase}}{{feature_name}}{{/snakeCase}}.freezed.dart';
{{/needs_freezed}}{{#needs_part_g}}part '{{#snakeCase}}{{feature_name}}{{/snakeCase}}.g.dart';
{{/needs_part_g}}
