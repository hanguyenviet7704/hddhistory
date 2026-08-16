// Regression tests for "the floating nav bar disappears after leaving the
// roadmap of a generated lesson".
//
// Two independent claims are pinned here, because a fix was twice attempted
// against the wrong one:
//
// 1. A pop reports the page it actually lands on. The route observer's `didPop`
//    carries the real route underneath for every way into the user-lesson
//    roadmap, so a back handler must NOT hard-code the name of the page it
//    assumes is below it (it is My Creations only on the shelf path).
// 2. A page in a BACKGROUNDED shell branch still looks like the current route to
//    `ModalRoute.isCurrent` — which is why `shouldAssertOwnRouteName` also
//    demands that the page's branch be the one on screen. Without that, the
//    lesson reader (course branch) reclaimed `lesson` after the reader had moved
//    to Profile and killed the nav bar there.
//
// The harness mirrors the real tree's SHAPE rather than importing it — a nested
// stack inside one shell branch, plus a second branch to cross into — so it is
// unaffected by which branch actually owns the shelf (it moved from Setting to
// Library with the Library tab). Its stand-in stack is profile → my-lessons →
// lesson-reader, a
// second branch to cross into, and the same page type the app builds
// (`CustomTransitionPage` carrying `name: state.name`, see
// `BaseTransitionRouteData.buildPage`).
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// Records what each navigator observer reports, the way `BaseRouterObserver`
/// forwards `previousRoute`'s name into `PageCubit.setCurrentRouteName`.
class _Recorder extends NavigatorObserver {
  _Recorder(this.observerName, this.events);

  final String observerName;
  final List<String> events;

  String _name(Route<dynamic>? route) => route == null ? '<null>' : (route.settings.name ?? '<unnamed>');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('$observerName didPush ${_name(route)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('$observerName didPop ${_name(route)} → ${_name(previousRoute)}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('$observerName didRemove ${_name(route)} → ${_name(previousRoute)}');
}

Page<void> _page(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  name: state.name,
  key: state.pageKey,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
  child: child,
);

Page<void> _labelPage(GoRouterState state, String label) => _page(state, Scaffold(body: Center(child: Text(label))));

/// Reports what [shouldAssertOwnRouteName] would be told from inside a page:
/// whether it is the current route, and whether its branch is on screen.
class _RouteNameClaimProbe extends StatefulWidget {
  const _RouteNameClaimProbe({required this.onSample});

  /// `(isRouteCurrent, isBranchOnScreen)`.
  final void Function(bool, bool) onSample;

  @override
  State<_RouteNameClaimProbe> createState() => _RouteNameClaimProbeState();
}

class _RouteNameClaimProbeState extends State<_RouteNameClaimProbe> {
  @override
  Widget build(BuildContext context) {
    widget.onSample(
      ModalRoute.of(context)?.isCurrent ?? false,
      TickerMode.valuesOf(context).enabled,
    );
    return const Scaffold(body: Center(child: Text('READER')));
  }
}

void main() {
  group('leaving the user-lesson roadmap', () {
    late List<String> events;
    late GoRouter router;

    GoRouter buildRouter() => GoRouter(
      initialLocation: '/profile',
      observers: [_Recorder('root', events)],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: [
            StatefulShellBranch(
              observers: [_Recorder('setting', events)],
              routes: [
                GoRoute(
                  path: '/profile',
                  name: RouteNamed.profile,
                  pageBuilder: (context, state) => _labelPage(state, 'PROFILE'),
                  routes: [
                    GoRoute(
                      path: 'my-lessons',
                      name: RouteNamed.myLessons,
                      pageBuilder: (context, state) => _labelPage(state, 'MY CREATIONS'),
                      routes: [
                        GoRoute(
                          path: 'lesson-reader/:lessonId',
                          name: RouteNamed.lessonReader,
                          pageBuilder: (context, state) => _labelPage(state, 'ROADMAP'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              observers: [_Recorder('explore', events)],
              routes: [
                GoRoute(
                  path: '/course',
                  name: RouteNamed.course,
                  pageBuilder: (context, state) => _labelPage(state, 'EXPLORE'),
                  routes: [
                    GoRoute(
                      path: 'import-lesson',
                      name: RouteNamed.importLesson,
                      pageBuilder: (context, state) => _labelPage(state, 'IMPORT'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    setUp(() {
      events = <String>[];
      router = buildRouter();
    });

    tearDown(() => router.dispose());

    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    /// The roadmap's back button: a plain pop, no name asserted.
    Future<void> tapBack(WidgetTester tester) async {
      await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
      await tester.pumpAndSettle();
    }

    testWidgets('from the shelf, the pop names My Creations', (tester) async {
      await show(tester);
      router.push('/profile/my-lessons');
      await tester.pumpAndSettle();
      router.push('/profile/my-lessons/lesson-reader/abc');
      await tester.pumpAndSettle();
      events.clear();

      await tapBack(tester);

      expect(find.text('MY CREATIONS'), findsOneWidget);
      expect(events, contains('setting didPop ${RouteNamed.lessonReader} → ${RouteNamed.myLessons}'));
    });

    testWidgets('opened over Profile (popup/toast), the pop names Profile — not My Creations', (tester) async {
      await show(tester);
      router.push('/profile/my-lessons/lesson-reader/abc');
      await tester.pumpAndSettle();
      events.clear();

      await tapBack(tester);

      // The page underneath was never My Creations here: hard-coding that name
      // on the way out left a PRIMARY page (Profile) wearing a non-primary name,
      // which is exactly how the nav bar goes missing.
      expect(find.text('PROFILE'), findsOneWidget);
      expect(events, contains('setting didPop ${RouteNamed.lessonReader} → ${RouteNamed.profile}'));
    });

    testWidgets('opened from the import flow, the roadmap stacks on the Explore branch', (tester) async {
      await show(tester);
      router.go('/course/import-lesson');
      await tester.pumpAndSettle();
      router.push('/profile/my-lessons/lesson-reader/abc');
      await tester.pumpAndSettle();
      events.clear();

      await tapBack(tester);

      // A push lands on the navigator of the branch the reader is standing in,
      // NOT the branch the route is declared under.
      expect(find.text('IMPORT'), findsOneWidget);
      expect(events, contains('explore didPop ${RouteNamed.lessonReader} → ${RouteNamed.importLesson}'));
    });

    testWidgets('returned to by the reader exit (go), the pop names My Creations', (tester) async {
      await show(tester);
      router.go('/course/import-lesson');
      await tester.pumpAndSettle();
      // What `lesson_exit_flow`/`keypoint_complete_page` do on the way out of a
      // generated lesson: a cross-branch `go` that rebuilds the whole chain.
      router.go('/profile/my-lessons/lesson-reader/abc');
      await tester.pumpAndSettle();
      events.clear();

      await tapBack(tester);

      expect(find.text('MY CREATIONS'), findsOneWidget);
      expect(events, contains('setting didPop ${RouteNamed.lessonReader} → ${RouteNamed.myLessons}'));
    });
  });

  group('re-entering the generated-lesson deck', () {
    // Why `startImportedKeypointLesson` must CLAIM `RouteNamed.lesson` itself
    // (the way keypoint_complete_page claims its exit destinations): quitting a
    // generated lesson mid-keypoint leaves for another BRANCH, so the deck
    // route is never popped off the course branch. Coming back to it is then a
    // cross-branch `go` whose target the branch ALREADY shows — go_router just
    // re-activates the branch and no navigator observer fires at all, so the
    // roadmap's PRIMARY route name stays tracked and the floating nav pill
    // sits on top of the deck ("ở phần học AI gen thì bị nav che").
    late List<String> events;
    late GoRouter router;

    GoRouter buildRouter() => GoRouter(
      initialLocation: '/profile/my-lessons/lesson-reader/abc',
      observers: [_Recorder('root', events)],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: [
            StatefulShellBranch(
              observers: [_Recorder('setting', events)],
              routes: [
                GoRoute(
                  path: '/profile',
                  name: RouteNamed.profile,
                  pageBuilder: (context, state) => _labelPage(state, 'PROFILE'),
                  routes: [
                    GoRoute(
                      path: 'my-lessons',
                      name: RouteNamed.myLessons,
                      pageBuilder: (context, state) => _labelPage(state, 'MY CREATIONS'),
                      routes: [
                        GoRoute(
                          path: 'lesson-reader/:lessonId',
                          name: RouteNamed.lessonReader,
                          pageBuilder: (context, state) => _labelPage(state, 'ROADMAP'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              observers: [_Recorder('course', events)],
              routes: [
                GoRoute(
                  path: '/course-roadmap',
                  name: RouteNamed.courseRoadmap,
                  pageBuilder: (context, state) => _labelPage(state, 'COURSE ROADMAP'),
                  routes: [
                    GoRoute(
                      path: 'lesson',
                      name: RouteNamed.lesson,
                      pageBuilder: (context, state) => _labelPage(state, 'DECK'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    setUp(() {
      events = <String>[];
      router = buildRouter();
    });

    tearDown(() => router.dispose());

    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets('the FIRST entry is announced — didPush carries the deck name', (tester) async {
      await show(tester);
      events.clear();

      router.go('/course-roadmap/lesson');
      await tester.pumpAndSettle();

      expect(find.text('DECK'), findsOneWidget);
      expect(events, contains('course didPush ${RouteNamed.lesson}'));
    });

    testWidgets('re-entry after a mid-keypoint quit is SILENT — no observer event anywhere', (tester) async {
      await show(tester);
      router.go('/course-roadmap/lesson');
      await tester.pumpAndSettle();
      // Quit mid-keypoint (lesson_exit_flow): a cross-branch go — the deck
      // stays top of the course branch, nothing is popped.
      router.go('/profile/my-lessons/lesson-reader/abc');
      await tester.pumpAndSettle();
      events.clear();

      // Tap the keypoint again on the lesson's roadmap.
      router.go('/course-roadmap/lesson');
      await tester.pumpAndSettle();

      expect(find.text('DECK'), findsOneWidget);
      // No didPush/didPop/didRemove fires on ANY navigator: the route observer
      // cannot correct PageCubit.currentRouteName, so the entry sequence has to
      // set it itself or the nav pill stays over the deck.
      expect(events, isEmpty);
    });
  });

  group('shouldAssertOwnRouteName', () {
    test('claims only when the page is current AND its branch is on screen', () {
      expect(shouldAssertOwnRouteName(isRouteCurrent: true, isBranchOnScreen: true), isTrue);
      // The reported bug: current in a branch that is no longer displayed.
      expect(shouldAssertOwnRouteName(isRouteCurrent: true, isBranchOnScreen: false), isFalse);
      expect(shouldAssertOwnRouteName(isRouteCurrent: false, isBranchOnScreen: true), isFalse);
    });

    testWidgets('a page left behind in another branch is still isCurrent, but offscreen', (tester) async {
      bool? isRouteCurrent;
      bool? isBranchOnScreen;

      final router = GoRouter(
        initialLocation: '/lesson',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/lesson',
                    name: RouteNamed.lesson,
                    pageBuilder: (context, state) => _page(
                      state,
                      _RouteNameClaimProbe(
                        onSample: (current, onScreen) {
                          isRouteCurrent = current;
                          isBranchOnScreen = onScreen;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    name: RouteNamed.profile,
                    pageBuilder: (context, state) => _labelPage(state, 'PROFILE'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(shouldAssertOwnRouteName(isRouteCurrent: isRouteCurrent!, isBranchOnScreen: isBranchOnScreen!), isTrue);

      // Quitting a generated lesson moves to ANOTHER branch. The reader page is
      // never popped — the shell keeps every branch alive — so it stays mounted
      // and `isCurrent`, and only the ticker flag tells it to keep quiet.
      router.go('/profile');
      await tester.pumpAndSettle();

      expect(find.text('PROFILE'), findsOneWidget);
      expect(isRouteCurrent, isTrue, reason: 'the left-behind page still reads as the current route');
      expect(isBranchOnScreen, isFalse, reason: 'its branch is offstage, so it must not claim the route name');
      expect(shouldAssertOwnRouteName(isRouteCurrent: isRouteCurrent!, isBranchOnScreen: isBranchOnScreen!), isFalse);
    });
  });
}
