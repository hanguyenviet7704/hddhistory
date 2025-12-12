library;

//* Package imports
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Parts - internal files using 'part of'
part 'data/datasources/local/onboard_local_data_source.dart';
part 'data/datasources/remote/onboard_api.dart';
part 'data/models/onboard_intro_model.dart';
part 'data/models/onboard_model.dart';
part 'data/models/onboard_motivation.dart';
part 'data/models/onboard_option_model.dart';
part 'data/repositories/onboard_repository.dart';
part 'domain/entities/onboard_entity.dart';
part 'domain/entities/onboard_intro_entity.dart';
part 'domain/entities/onboard_motivation_entity.dart';
part 'domain/entities/onboard_option_entity.dart';
part 'domain/repositories/i_onboard_repository.dart';
part 'domain/usecases/get_all_onboards_usecase.dart';
//* Parts for generated files
part 'onboard.freezed.dart';
part 'onboard.g.dart';
//* State is shared between BLoC and Cubit
part 'presentation/cubits/intro/intro_cubit.dart';
part 'presentation/cubits/intro/intro_state.dart';
part 'presentation/cubits/onboard/onboard_cubit.dart';
part 'presentation/cubits/onboard/onboard_state.dart';
//* Pages
part 'presentation/pages/onboard_introduce_page.dart';
part 'presentation/pages/onboard_page.dart';
part 'presentation/pages/splash_page.dart';
//* Widgets
part 'presentation/widgets/character_illustration_widget.dart';
part 'presentation/widgets/character_section.dart';
part 'presentation/widgets/chat_bubble_widget.dart';
part 'presentation/widgets/content_card.dart';
part 'presentation/widgets/continue_button_widget.dart';
part 'presentation/widgets/force_update_content.dart';
part 'presentation/widgets/home_indicator_widget.dart';
part 'presentation/widgets/intro_content.dart';
part 'presentation/widgets/intro_header.dart';
part 'presentation/widgets/intro_language_sheet.dart';
part 'presentation/widgets/intro_step_content.dart';
part 'presentation/widgets/onboard_chat_item.dart';
part 'presentation/widgets/splash_content_card.dart';
part 'presentation/widgets/status_bar_widget.dart';
