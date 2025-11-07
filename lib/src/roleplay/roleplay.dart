library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/roleplay_local_data_source.dart';
part 'data/datasources/remote/roleplay_api.dart';
part 'data/models/conversation_model.dart';
part 'data/models/hint_model.dart';
part 'data/models/leading_text_model.dart';
part 'data/models/section_content_model.dart';
part 'data/models/section_model.dart';
part 'data/repositories/roleplay_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/conversation_entity.dart';
part 'domain/entities/hint_entity.dart';
part 'domain/entities/leading_text_entity.dart';
part 'domain/entities/section_content_entity.dart';
part 'domain/entities/section_entity.dart';
part 'domain/repositories/i_roleplay_repository.dart';
part 'domain/usecases/get_all_learning_items_usecase.dart';
part 'domain/usecases/get_learning_item_usecase.dart';
//* Presentation Layer - Cubits
part 'presentation/cubits/roleplay_cubit.dart';
part 'presentation/cubits/roleplay_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/roleplay_complete_page.dart';
part 'presentation/pages/roleplay_feedback_page.dart';
part 'presentation/pages/roleplay_intro_page.dart';
part 'presentation/pages/roleplay_page.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'roleplay.freezed.dart';
part 'roleplay.g.dart';
