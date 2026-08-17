part of '../routes.dart';

//* Shell routes - Library
class LibraryShellBranchData extends StatefulShellBranchData {
  const LibraryShellBranchData();
  static final List<NavigatorObserver> $observers = [AppConfig.instance.libraryRouterObserver];
}

/// The Library tab (design `5b · Library`): what you are part-way through, the
/// full history behind it, and the shelf of lessons you made yourself.
///
/// It took the Profile tab's slot in the bottom bar — Profile is still a shell
/// branch of its own, reached from the Home header avatar.
class LibraryRoute extends BaseTransitionRouteData with $LibraryRoute {
  const LibraryRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  /// [UserLessonCubit] is provided at the tab root, not only on My Creations:
  /// the Library screen's My Creations row shows how many lessons are on that
  /// shelf, so it reads the same cubit the shelf itself does.
  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<SavedCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const LibraryPage(),
  );
}

/// "My history" — every enrolled course, filtered In progress / Finished.
class LibraryHistoryRoute extends BaseTransitionRouteData with $LibraryHistoryRoute {
  const LibraryHistoryRoute();

  /// Rises from the bottom rather than zooming up: it opens from a text link in
  /// the middle of the tab, and reads as a panel pulled up over the Library —
  /// the same move Daily check-in and the import form make.
  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const LibraryHistoryPage(),
  );
}

/// "Saved" — the courses the reader bookmarked, filtered Up next / In progress
/// / Finished.
///
/// Same rise-from-the-bottom as My history: both are panels pulled up over the
/// Library from a row in the middle of the tab.
class SavedCoursesRoute extends BaseTransitionRouteData with $SavedCoursesRoute {
  const SavedCoursesRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<SavedCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const SavedCoursesPage(),
  );
}

/// "Saved cards" — the recap cards kept from the end of a keypoint, as a grid
/// or a deck.
class SavedCardsRoute extends BaseTransitionRouteData with $SavedCardsRoute {
  const SavedCardsRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<SavedCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const SavedCardsPage(),
  );
}

/// The user's shelf of self-generated lessons, reached from the Library tab.
///
/// Both cubits are provided here rather than in the page: the import flow's
/// polling outlives the sheet that started it (the user is explicitly allowed
/// to walk away mid-generation), so its cubit must not be scoped to a widget.
class MyLessonsRoute extends BaseTransitionRouteData with $MyLessonsRoute {
  const MyLessonsRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LearningImportCubit>()),
    ],
    child: const MyLessonsPage(),
  );
}

class LessonReaderRoute extends BaseTransitionRouteData with $LessonReaderRoute {
  const LessonReaderRoute(this.lessonId);

  final String lessonId;

  /// A plain fade — neither a right-hand push nor a zoom.
  ///
  /// This screen is arrived at from four places (the progress toast, the done
  /// popup, the generating screen, the shelf) and left by two more, none of
  /// which is a forward step in a flow. A slide says "deeper in", and `scale`
  /// — the catalogue roadmap's choice — reads as the screen zooming up at you.
  /// A fade says the thing it should: you are looking at it now.
  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  /// Lands on the lesson's ROADMAP, not in the deck. It used to hand straight
  /// off to the reader, which left a generated lesson with no page of its own —
  /// nothing to come back to, nowhere to hang practice off. The roadmap's CTA
  /// does what this route used to do on arrival.
  ///
  /// Only [UserLessonCubit] is needed now. The route used to also create a
  /// per-entry audio cubit for a reader this feature owned; the lesson is read
  /// by the catalogue's own screen these days, and that screen brings its own
  /// player (see `_buildLessonFlowPage`).
  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<UserLessonCubit>(),
    child: UserLessonRoadmapPage(lessonId: lessonId),
  );
}
