{{#include_state_management}}
{{^use_bloc}}
part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit extends Cubit<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State>
    with CubitUseCaseHandlerMixin<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> {
  {{#has_list}}final GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase _getAllUseCase;
  {{/has_list}}{{#has_detail}}final Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _getUseCase;
  {{/has_detail}}{{#has_create}}final Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _createUseCase;
  {{/has_create}}{{#has_update}}final Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _updateUseCase;
  {{/has_update}}{{#has_delete}}final Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _deleteUseCase;
  {{/has_delete}}

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit(
    {{#has_list}}this._getAllUseCase,
    {{/has_list}}{{#has_detail}}this._getUseCase,
    {{/has_detail}}{{#has_create}}this._createUseCase,
    {{/has_create}}{{#has_update}}this._updateUseCase,
    {{/has_update}}{{#has_delete}}this._deleteUseCase,
    {{/has_delete}}
  ) : super({{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial());

  {{#has_list}}void loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s({bool isInit = false}) async {
    if (!isInit && state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    final pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

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

  {{/has_list}}{{#has_detail}}void load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
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

  {{/has_detail}}{{#has_create}}{{#has_list}}void create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
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
          {{#has_detail}}selectedItem: newItem,{{/has_detail}}
        ));
      },
    );
  }
  {{/has_list}}{{#no_list}}void create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
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
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: newItem,{{/has_detail}}
        ));
      },
    );
  }
  {{/no_list}}{{/has_create}}{{#has_update}}{{#has_list}}void update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
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
        final updatedItems =
            state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
          {{#has_detail}}selectedItem: updatedItem,{{/has_detail}}
        ));
      },
    );
  }
  {{/has_list}}{{#no_list}}void update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) async {
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
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: updatedItem,{{/has_detail}}
        ));
      },
    );
  }
  {{/no_list}}{{/has_update}}{{#has_delete}}{{#has_list}}void delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
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
  {{/has_list}}{{#no_list}}void delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) async {
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
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: state.selectedItem?.id == id ? null : state.selectedItem,{{/has_detail}}
        ));
      },
    );
  }
  {{/no_list}}{{/has_delete}}
}
{{/use_bloc}}
{{/include_state_management}}
