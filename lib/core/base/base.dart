library;

//* Import all default dart libraries here
import 'dart:async';
import 'dart:isolate';

//* Import all dependencies here
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show OperationException, QueryResult;

//* Import all local files here
import '../../config/di/di.dart';
import '../../config/services/services.dart';
import '../../src/common/presentation/blocs/blocs.dart';
import '../helpers/helpers.dart';

//* Import all base files here
part 'base.freezed.dart';
part 'base.g.dart';
part 'bloc/bloc_action_handler.dart';
part 'bloc/bloc_usecase_handler.dart';
part 'bloc/cubit_action_handler.dart';
part 'bloc/cubit_usecase_handler.dart';
part 'error/app_exception.dart';
part 'network/graphql_request.dart';
part 'network/restful_request.dart';
part 'request/page_break_request.dart';
part 'responses/base_multi_language.dart';
part 'responses/base_page_break.dart';
part 'responses/base_response.dart';
part 'responses/base_socket_response.dart';
part 'use_case/use_case.dart';
