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

  void loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
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

  void load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _getUseCase(id),
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

  void create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _createUseCase(entity),
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

  void update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
    await runUseCase<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>(
      usecase: () => _updateUseCase(entity),
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

  void delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
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
