import 'package:mason/mason.dart';

void run(HookContext context) {
  final vars = context.vars;

  var entityName = (vars['entity_name'] as String? ?? '').trim();
  final featureName = (vars['feature_name'] as String? ?? '').trim();

  if (entityName.isEmpty) {
    entityName = featureName;
    context.logger.warn(
      'entity_name was empty, defaulting to feature_name ("$featureName").',
    );
    vars['entity_name'] = entityName;
  }

  final architectureProfile =
      (vars['architecture_profile'] as String? ?? 'full_stack').trim();
  final includeDomainLayer = architectureProfile != 'presentation_only';
  final includeDataLayer = architectureProfile == 'full_stack';
  final includeStateManagement = includeDomainLayer;

  final wantsRemote = vars['include_remote_datasource'] as bool? ?? true;
  final wantsLocalCache = vars['include_local_cache'] as bool? ?? true;

  var hasRemote = includeDataLayer && wantsRemote;
  var hasLocalCache = includeDataLayer && wantsLocalCache;

  if (includeDataLayer && !hasRemote && !hasLocalCache) {
    context.logger.warn(
      'include_data_layer is enabled but both remote and local data sources were disabled. Enabling remote data source by default.',
    );
    hasRemote = true;
  }

  final crudRaw = (vars['crud_operations'] as String? ?? '').trim();
  final normalizedCrud = crudRaw.isEmpty
      ? <String>{}
      : crudRaw
          .split(',')
          .map((op) => op.trim().toLowerCase())
          .where((op) => op.isNotEmpty)
          .toSet();

  if (normalizedCrud.isEmpty) {
    normalizedCrud.addAll({'list', 'detail', 'create', 'update', 'delete'});
    context.logger.warn(
        'No CRUD operations provided, defaulting to list/detail/create/update/delete.');
  }

  final hasList = normalizedCrud.contains('list');
  final hasDetail = normalizedCrud.contains('detail');
  final hasCreate = normalizedCrud.contains('create');
  final hasUpdate = normalizedCrud.contains('update');
  final hasDelete = normalizedCrud.contains('delete');
  final hasRead = hasList || hasDetail;
  final hasWrite = hasCreate || hasUpdate || hasDelete;
  final hasItemActions = hasUpdate || hasDelete;
  final noList = !hasList;

  final presentationProfile =
      (vars['presentation_profile'] as String? ?? 'paged_list').trim();
  final isPagedList = presentationProfile == 'paged_list';
  final isSingleItem = presentationProfile == 'single_item';
  final isBlankScreen = presentationProfile == 'blank_screen';

  final needsFreezed =
      includeDomainLayer || includeDataLayer || includeStateManagement;
  final needsInjectable =
      includeDomainLayer || includeDataLayer || includeStateManagement;
  final needsPartG = needsFreezed || hasRemote;

  vars['include_domain_layer'] = includeDomainLayer;
  vars['include_data_layer'] = includeDataLayer;
  vars['include_state_management'] = includeStateManagement;
  vars['has_remote_datasource'] = hasRemote;
  vars['has_local_cache'] = hasLocalCache;
  vars['has_list'] = hasList;
  vars['has_detail'] = hasDetail;
  vars['has_create'] = hasCreate;
  vars['has_update'] = hasUpdate;
  vars['has_delete'] = hasDelete;
  vars['has_crud_read'] = hasRead;
  vars['has_crud_write'] = hasWrite;
  vars['has_item_actions'] = hasItemActions;
  vars['no_list'] = noList;
  vars['is_paged_list'] = isPagedList;
  vars['is_single_item'] = isSingleItem;
  vars['is_blank_screen'] = isBlankScreen;
  vars['needs_freezed'] = needsFreezed;
  vars['needs_injectable'] = needsInjectable;
  vars['needs_fpdart'] = includeDomainLayer;
  vars['needs_retrofit'] = hasRemote;
  vars['needs_part_g'] = needsPartG;
}
