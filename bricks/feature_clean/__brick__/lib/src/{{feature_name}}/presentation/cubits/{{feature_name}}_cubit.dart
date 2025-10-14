{{^use_bloc}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit extends Cubit<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> with CubitUseCaseHandlerMixin<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> {
  final GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase _getAllUseCase;
  final Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _getUseCase;
  final Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _createUseCase;
  final Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _updateUseCase;
  final Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _deleteUseCase;

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super({{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial());

  Future<void> loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s() async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _getAllUseCase().run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          items: items,
        ),
      ),
    );
  }

  Future<void> load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _getUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (item) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          selectedItem: item,
        ),
      ),
    );
  }

  Future<void> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _createUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (newItem) {
        final updatedItems = [...state.items, newItem];
        emit(
          state.copyWith(
            status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
            items: updatedItems,
          ),
        );
      },
    );
  }

  Future<void> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _updateUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (updatedItem) {
        final updatedItems = state.items
            .map((item) => item.id == updatedItem.id ? updatedItem : item)
            .toList();
        emit(
          state.copyWith(
            status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
            items: updatedItems,
            selectedItem: updatedItem,
          ),
        );
      },
    );
  }

  Future<void> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _deleteUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (_) {
        final updatedItems = state.items.where((item) => item.id != id).toList();
        emit(
          state.copyWith(
            status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
            items: updatedItems,
          ),
        );
      },
    );
  }
}
{{/use_bloc}}