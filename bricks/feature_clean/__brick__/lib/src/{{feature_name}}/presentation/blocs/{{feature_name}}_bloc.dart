{{#include_state_management}}
{{#use_bloc}}
part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc extends Bloc<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Event, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State> with BlocUseCaseHandlerMixin<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Event, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State> {
  {{#has_list}}final GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase _getAllUseCase;
  {{/has_list}}{{#has_detail}}final Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _getUseCase;
  {{/has_detail}}{{#has_create}}final Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _createUseCase;
  {{/has_create}}{{#has_update}}final Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _updateUseCase;
  {{/has_update}}{{#has_delete}}final Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase _deleteUseCase;
  {{/has_delete}}

  {{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc(
    {{#has_list}}this._getAllUseCase,
    {{/has_list}}{{#has_detail}}this._getUseCase,
    {{/has_detail}}{{#has_create}}this._createUseCase,
    {{/has_create}}{{#has_update}}this._updateUseCase,
    {{/has_update}}{{#has_delete}}this._deleteUseCase,
    {{/has_delete}}
  ) : super({{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial()) {
    {{#has_list}}on<_LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s>(_onLoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s);
    {{/has_list}}{{#has_detail}}on<_Load{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onLoad{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    {{/has_detail}}{{#has_create}}on<_Create{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onCreate{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    {{/has_create}}{{#has_update}}on<_Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onUpdate{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    {{/has_update}}{{#has_delete}}on<_Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}>(_onDelete{{#pascalCase}}{{entity_name}}{{/pascalCase}});
    {{/has_delete}}
  }

  {{#has_list}}Future<void> _onLoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    _LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s event,
    Emitter<{{#pascalCase}}{{feature_name}}{{/pascalCase}}State> emit,
  ) async {
    if (!event.isInit && state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading) return;
    if (!event.isInit && state.pageData.isLastPage) return;

    final pageRequest = event.isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

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
  {{/has_list}}

  {{#has_detail}}Future<void> _onLoad{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
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
  {{/has_detail}}

  {{#has_create}}Future<void> _onCreate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
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
        {{#has_list}}final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
          {{#has_detail}}selectedItem: newItem,{{/has_detail}}
        ));{{/has_list}}{{#no_list}}
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: newItem,{{/has_detail}}
        ));{{/no_list}}
      },
    );
  }
  {{/has_create}}

  {{#has_update}}Future<void> _onUpdate{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
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
        {{#has_list}}final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
          {{#has_detail}}selectedItem: updatedItem,{{/has_detail}}
        ));{{/has_list}}{{#no_list}}
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: updatedItem,{{/has_detail}}
        ));{{/no_list}}
      },
    );
  }
  {{/has_update}}

  {{#has_delete}}Future<void> _onDelete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(
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
        {{#has_list}}final updatedItems = state.pageData.items.where((item) => item.id != event.id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          pageData: updatedPageData,
        ));{{/has_list}}{{#no_list}}
        emit(state.copyWith(
          status: {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success,
          {{#has_detail}}selectedItem: state.selectedItem?.id == event.id ? null : state.selectedItem,{{/has_detail}}
        ));{{/no_list}}
      },
    );
  }
  {{/has_delete}}
}
{{/use_bloc}}
{{/include_state_management}}
