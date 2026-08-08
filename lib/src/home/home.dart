library;

//* Package imports
import 'package:darq/darq.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
//* Single project import
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';
import 'package:skeletonizer/skeletonizer.dart' as sk;

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/home_local_data_source.dart';
part 'data/datasources/remote/skillset_api.dart';
part 'data/datasources/remote/home_api.dart';
part 'data/models/skillset_model.dart';
part 'data/models/quote_model.dart';
part 'data/models/suggested_course_model.dart';
part 'data/models/home_banner_model.dart';
part 'data/repositories/home_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/skillset_entity.dart';
part 'domain/entities/quote_entity.dart';
part 'domain/entities/suggested_course_entity.dart';
part 'domain/entities/home_banner_entity.dart';
part 'domain/repositories/i_home_repository.dart';
part 'domain/usecases/get_all_skillsets_usecase.dart';
part 'domain/usecases/get_skillset_usecase.dart';
part 'domain/usecases/get_random_quote_usecase.dart';
part 'domain/usecases/get_suggest_courses_usecase.dart';
part 'domain/usecases/get_home_banner_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'home.freezed.dart';
part 'home.g.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/home_cubit.dart';
part 'presentation/cubits/home_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/home_page.dart';
part 'presentation/helpers/home_tracking.dart';
part 'presentation/mixins/home_in_app_survey_mixin.dart';
part 'presentation/mixins/home_daily_warm_up_mixin.dart';
//* Presentation Layer - Custom Widgets
part 'presentation/widgets/course_card.dart';
part 'presentation/widgets/got_ideas_banner.dart';
part 'presentation/widgets/home_banner_card.dart';
part 'presentation/widgets/home_header.dart';
part 'presentation/widgets/home_quote_card.dart';
part 'presentation/widgets/home_widget_debug_payload_builder.dart';
part 'presentation/widgets/section_header.dart';
part 'presentation/widgets/skillset_card.dart';
part 'presentation/widgets/update_header.dart';
