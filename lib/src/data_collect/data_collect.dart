library;

//* Single project import
import 'package:meup/meup.dart';

//* Package imports
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

//* Parts - internal files using 'part of'
part 'data/models/user_collect_data_model.dart';
part 'data/datasources/remote/data_collect_api.dart';
part 'data/datasources/local/data_collect_local_data_source.dart';
part 'data/repositories/data_collect_repository.dart';
part 'domain/entities/user_collect_data_entity.dart';
part 'domain/repositories/i_data_collect_repository.dart';
part 'domain/usecases/get_user_collect_data_usecase.dart';
part 'domain/usecases/get_all_user_collect_datas_usecase.dart';
part 'domain/usecases/create_user_collect_data_usecase.dart';
part 'domain/usecases/update_user_collect_data_usecase.dart';
part 'domain/usecases/delete_user_collect_data_usecase.dart';
//* State is shared between BLoC and Cubit
part 'presentation/cubits/data_collect_state.dart';
part 'presentation/cubits/data_collect_cubit.dart';
part 'presentation/pages/data_collect_page.dart';

//* Parts for generated files
part 'data_collect.freezed.dart';
part 'data_collect.g.dart';
