library;

//* Single project import
// Cũng tái xuất dart:async (Timer, unawaited) và flutter_bloc — import trực
// tiếp ở đây sẽ bị báo thừa.
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Domain Layer - Entities
part 'domain/entities/kg_entity.dart';

//* Data Layer - Models, Datasource, Repository impl
part 'data/models/kg_models.dart';
part 'data/datasources/remote/knowledge_graph_api.dart';
part 'data/repositories/knowledge_graph_repository.dart';

//* Domain Layer - Repository interface, Use cases
part 'domain/repositories/i_knowledge_graph_repository.dart';
part 'domain/usecases/search_kg_entities_usecase.dart';
part 'domain/usecases/get_kg_entity_profile_usecase.dart';
part 'domain/usecases/get_kg_related_entities_usecase.dart';

//* Presentation Layer - Cubit + State
part 'presentation/cubits/knowledge_graph_state.dart';
part 'presentation/cubits/knowledge_graph_cubit.dart';

//* Presentation Layer - Widgets
part 'presentation/widgets/kg_labels.dart';
part 'presentation/widgets/kg_entity_tile.dart';
part 'presentation/widgets/kg_entry_card.dart';

//* Presentation Layer - Pages
part 'presentation/pages/knowledge_graph_search_page.dart';
part 'presentation/pages/knowledge_graph_profile_page.dart';

//* Parts for generated files
part 'knowledge_graph.freezed.dart';
part 'knowledge_graph.g.dart';
