part of '../routes.dart';

/// Tra cứu đồ thị tri thức lịch sử — mở từ thẻ trên tab Thư viện.
///
/// Fade như các hàng khác của tab Thư viện: đây là một danh sách mở ra từ giữa
/// tab, không phải một bước đi sâu hơn trong một luồng.
class KnowledgeGraphSearchRoute extends BaseTransitionRouteData
    with $KnowledgeGraphSearchRoute {
  const KnowledgeGraphSearchRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) =>
      BlocProvider.value(
        value: AppDI.injector.get<KnowledgeGraphCubit>(),
        child: const KnowledgeGraphSearchPage(),
      );
}

/// Hồ sơ một thực thể. Tự trỏ lại chính mình được: từ hồ sơ này bấm sang một
/// thực thể liên quan là push thêm một [KnowledgeGraphEntityRoute] nữa, nên
/// người dùng lần theo đồ thị mà vẫn back về đúng đường đã đi.
class KnowledgeGraphEntityRoute extends BaseTransitionRouteData
    with $KnowledgeGraphEntityRoute {
  const KnowledgeGraphEntityRoute(this.entityId);

  final String entityId;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) =>
      BlocProvider.value(
        value: AppDI.injector.get<KnowledgeGraphCubit>(),
        child: KnowledgeGraphProfilePage(entityId: entityId),
      );
}
