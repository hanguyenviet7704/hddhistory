library;

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/monetization_local_data_source.dart';
part 'data/datasources/remote/monetization_api.dart';
part 'data/models/feature_model.dart';
part 'data/models/iap_product_model.dart';
part 'data/models/iap_verify_model.dart';
part 'data/models/payment_provider_model.dart';
part 'data/repositories/monetization_repository.dart';
//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/feature_entity.dart';
part 'domain/entities/iap_product_entity.dart';
part 'domain/entities/iap_verify_entity.dart';
part 'domain/entities/payment_provider_entity.dart';
part 'domain/repositories/i_monetization_repository.dart';
part 'domain/usecases/get_packages_usecase.dart';
part 'domain/usecases/purchase_usecase.dart';
part 'domain/usecases/restore_usecase.dart';
part 'domain/usecases/verify_android_usecase.dart';
part 'domain/usecases/verify_ios_usecase.dart';
//* Presentation Layer - Widgets

//* Parts for generated files
part 'monetization.freezed.dart';
part 'monetization.g.dart';
part 'presentation/cubits/monetization_cubit.dart';
//* Presentation Layer - BLoC or Cubit - States, Events, Cubits, Blocs
part 'presentation/cubits/monetization_state.dart';
//* Presentation Layer - Pages
part 'presentation/pages/monetization_page.dart';
