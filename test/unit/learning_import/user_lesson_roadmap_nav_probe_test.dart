// PROBE — evidence-gathering for the "nav bar disappears after leaving the
// user-lesson roadmap" report. Mirrors the real route tree's shape (a stateful
// shell, the Setting branch's profile → my-lessons → lesson-reader chain, and a
// second branch to push across) with the same page type the app uses
// (CustomTransitionPage carrying `name: state.name`), then records every
// navigator-observer callback so we can see WHICH name the shell's nav gate
// would end up with after each way out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Recorder extends NavigatorObserver {
  _Recorder(this.observerName, this.events);

  final String observerName;
  final List<String> events;

  String _n(Route<dynamic>? r) => r == null ? '<null>' : '${r.settings.name ?? '<unnamed>'}';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('$observerName didPush ${_n(route)} prev=${_n(previousRoute)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('$observerName didPop ${_n(route)} prev=${_n(previousRoute)}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('$observerName didRemove ${_n(route)} prev=${_n(previousRoute)}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      events.add('$observerName didReplace ${_n(newRoute)} old=${_n(oldRoute)}');
}

Page<void> _page(GoRouterState state, String label) => CustomTransitionPage<void>(
  name: state.name,
  key: state.pageKey,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
  child: Scaffold(body: Center(child: Text(label))),
);

void main() {
  late List<String> events;
  late GoRouter router;

  setUp(() {
    events = <String>[];
    router = GoRouter(
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
                  name: 'Profile',
                  pageBuilder: (c, s) => _page(s, 'PROFILE'),
                  routes: [
                    GoRoute(
                      path: 'my-lessons',
                      name: 'My Lessons',
                      pageBuilder: (c, s) => _page(s, 'MY LESSONS'),
                      routes: [
                        GoRoute(
                          path: 'lesson-reader/:lessonId',
                          name: 'Lesson Reader',
                          pageBuilder: (c, s) => _page(s, 'ROADMAP'),
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
                  name: 'Course',
                  pageBuilder: (c, s) => _page(s, 'COURSE'),
                  routes: [
                    GoRoute(
                      path: 'import-lesson',
                      name: 'Import Lesson',
                      pageBuilder: (c, s) => _page(s, 'IMPORT'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  void dump(String label, WidgetTester tester) {
    // ignore: avoid_print
    print('\n=== $label ===\n${events.join('\n')}\nrouter.state.name=${router.state.name}  location=${router.state.uri}');
    events.clear();
  }

  testWidgets('A: shelf path — profile > my-lessons > roadmap, then pop', (tester) async {
    await pump(tester);
    router.push('/profile/my-lessons');
    await tester.pumpAndSettle();
    router.push('/profile/my-lessons/lesson-reader/abc');
    await tester.pumpAndSettle();
    dump('A entry', tester);
    expect(find.text('ROADMAP'), findsOneWidget);

    // What the roadmap's back button does today.
    await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
    await tester.pumpAndSettle();
    dump('A pop', tester);
    expect(find.text('MY LESSONS'), findsOneWidget);
  });

  testWidgets('B: popup path — roadmap pushed straight onto profile, then pop', (tester) async {
    await pump(tester);
    router.push('/profile/my-lessons/lesson-reader/abc');
    await tester.pumpAndSettle();
    dump('B entry', tester);

    await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
    await tester.pumpAndSettle();
    dump('B pop', tester);
  });

  testWidgets('C: cross-branch — pushed from the Explore branch, then pop', (tester) async {
    await pump(tester);
    router.go('/course/import-lesson');
    await tester.pumpAndSettle();
    events.clear();
    router.push('/profile/my-lessons/lesson-reader/abc');
    await tester.pumpAndSettle();
    dump('C entry', tester);

    await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
    await tester.pumpAndSettle();
    dump('C pop', tester);
  });

  testWidgets('D: go() back to the roadmap (reader exit), then pop', (tester) async {
    await pump(tester);
    router.go('/course/import-lesson');
    await tester.pumpAndSettle();
    events.clear();
    router.go('/profile/my-lessons/lesson-reader/abc');
    await tester.pumpAndSettle();
    dump('D entry', tester);

    await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
    await tester.pumpAndSettle();
    dump('D pop', tester);
  });
}
