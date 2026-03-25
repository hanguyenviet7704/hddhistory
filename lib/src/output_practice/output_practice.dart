library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

//* Data Layer - Models, Datasources, Repositories
part 'data/models/output_practice_ai_reply_option_model.dart';
part 'data/models/output_practice_ai_reply_model.dart';
part 'data/models/output_practice_conversation_model.dart';
part 'data/models/output_practice_message_model.dart';
part 'data/models/output_practice_ai_start_response_model.dart';
part 'data/models/output_practice_ai_stream_event_model.dart';
part 'data/datasources/remote/output_practice_api.dart';
part 'data/datasources/remote/output_practice_socket_data_source.dart';
part 'data/datasources/remote/output_practice_socket_event.dart';
part 'data/datasources/local/output_practice_local_data_source.dart';
part 'data/repositories/output_practice_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/output_practice_ai_reply_option_entity.dart';
part 'domain/entities/output_practice_ai_reply_entity.dart';
part 'domain/entities/output_practice_conversation_entity.dart';
part 'domain/entities/output_practice_message_entity.dart';
part 'domain/repositories/i_output_practice_repository.dart';
part 'domain/usecases/get_all_output_practice_messages_usecase.dart';
part 'domain/usecases/get_output_practice_conversation_usecase.dart';
part 'domain/usecases/create_output_practice_conversation_usecase.dart';
part 'domain/usecases/send_output_practice_message_usecase.dart';

//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/output_practice_state.dart';
part 'presentation/cubits/output_practice_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/output_practice_page.dart';

//* Presentation Layer - Widgets

//* Parts for generated files
part 'output_practice.freezed.dart';
part 'output_practice.g.dart';
