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
    // Prevent multiple simultaneous loads
    if (!event.isInit && state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!event.isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = event.isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: event.isInit,
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: pageData,
        ));
      },
    );
  }

  Future<void> _onLoad{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Load{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _getUseCase(event.id),
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          selectedItem: item,
        ));
      },
    );
  }

  Future<void> _onCreate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Create{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _createUseCase(event.entity),
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  Future<void> _onUpdate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Update{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _updateUseCase(event.entity),
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  Future<void> _onDelete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
    _Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}} event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(event.id),
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != event.id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}
{{/use_bloc}}
