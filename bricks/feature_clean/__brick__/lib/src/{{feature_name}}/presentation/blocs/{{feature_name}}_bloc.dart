{{#use_bloc}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc extends Bloc<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Event, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State> with BlocUseCaseHandlerMixin<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Event, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State> {
  final GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase _getAllUseCase;
  final Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _getUseCase;
  final Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _createUseCase;
  final Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _updateUseCase;
  final Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _deleteUseCase;

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super({{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial()) {
    on<_LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s>(_onLoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s);
    on<_Load{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onLoad{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    on<_Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onCreate{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    on<_Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onUpdate{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    on<_Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onDelete{{#pascalCase}}{{entity_name}}{{/pascalCase}});
  }

  Future<void> _onLoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    _LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
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

  Future<void> _onLoad{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Load{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _getUseCase(event.id).run();

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

  Future<void> _onCreate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Create{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _createUseCase(event.entity).run();

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

  Future<void> _onUpdate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Update{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _updateUseCase(event.entity).run();

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

  Future<void> _onDelete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    emit(state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading));

    final result = await _deleteUseCase(event.id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: exception.message,
        ),
      ),
      (_) {
        final updatedItems = state.items.where((item) => item.id != event.id).toList();
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