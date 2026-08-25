part of '../routes.dart';

//* Shell routes - Community
class CommunityShellBranchData extends StatefulShellBranchData {
  const CommunityShellBranchData();
  static final List<NavigatorObserver> $observers = [AppConfig.instance.communityRouterObserver];
}

//* Community Route — the fifth nav tab (design `13 · Community`). Registered
//* inside its own shell branch so CommunityPage renders within the shell and
//* keeps the bottom navigation bar.
class CommunityRoute extends BaseTransitionRouteData with $CommunityRoute {
  const CommunityRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CommunityFeedCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const CommunityPage(),
  );
}

class CommunityTopicRoute extends BaseTransitionRouteData with $CommunityTopicRoute {
  const CommunityTopicRoute({required this.topicId});

  final String topicId;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    // Reuses the hub's cubit on purpose: following a topic here has to show up
    // on the topics tab immediately, and both read the same follow list.
    value: AppDI.injector.get<CommunityFeedCubit>(),
    child: CommunityTopicPage(topicId: topicId),
  );
}

/// One thread. A NEW cubit per push (`injectable` factory), so two posts open on
/// the stack are two independent threads — sharing one would make the back
/// gesture reveal the wrong comments.
class CommunityPostRoute extends BaseTransitionRouteData with $CommunityPostRoute {
  const CommunityPostRoute({required this.postId});

  final String postId;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => AppDI.injector.get<CommunityPostCubit>()..loadPost(postId),
    child: CommunityPostDetailPage(postId: postId),
  );
}

class CommunityWeeklyRoute extends BaseTransitionRouteData with $CommunityWeeklyRoute {
  const CommunityWeeklyRoute();

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => AppDI.injector.get<CommunityPostCubit>()..loadWeekly(),
    child: const CommunityWeeklyPage(),
  );
}

/// A group chat room. Slides up from the bottom and hides the nav pill: the
/// design opens it as a sheet OVER the forum, not as a sixth tab.
///
/// A new cubit per push (`injectable` factory) — the room polls while it is
/// open, and a singleton would keep doing that after the reader has left.
class CommunityChatRoute extends BaseTransitionRouteData with $CommunityChatRoute {
  const CommunityChatRoute({required this.room});

  /// The room's SLUG, so the app names the room instead of carrying its id.
  final String room;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => AppDI.injector.get<CommunityChatCubit>(),
    child: CommunityChatPage(room: room),
  );
}

class CommunityComposeRoute extends BaseTransitionRouteData with $CommunityComposeRoute {
  const CommunityComposeRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider(
        // applyPendingSeed drains the hand-off from a "Đăng vào Confession"
        // share, so the attachment is on screen in the composer's FIRST frame.
        create: (_) => AppDI.injector.get<CommunityComposeCubit>()..applyPendingSeed(),
      ),
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
    ],
    child: const CommunityComposePage(),
  );
}

class CommunityNotificationRoute extends BaseTransitionRouteData with $CommunityNotificationRoute {
  const CommunityNotificationRoute();

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => AppDI.injector.get<CommunityNotificationCubit>(),
    child: const CommunityNotificationPage(),
  );
}
