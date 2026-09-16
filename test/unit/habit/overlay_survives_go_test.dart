// Đo hành vi điều hướng nền dưới báo lỗi "bấm ✕ ở lời mời Coach lại đứng
// nguyên trên trang thêm thói quen".
//
// `HabitSuggestPage.push` dùng `Navigator.of(context, rootNavigator: true)
// .push(...)`; `openCourseRoadmapFromCoach` thì gọi `CourseRoadmapRoute().go()`
// rồi trả `true` VÔ ĐIỀU KIỆN, nên người gọi `return` mà không pop.
//
// Câu hỏi: `.go()` có tự dọn cái route mệnh lệnh đó không? Câu trả lời KHÁC
// NHAU tuỳ hình dạng cây route, nên ở đây đo cả hai — và chính chỗ khác nhau
// đó là lỗi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _screen(String label) => Scaffold(body: Center(child: Text(label)));

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

void _push(BuildContext context, String label) {
  Navigator.of(context, rootNavigator: true)
      .push<void>(MaterialPageRoute(builder: (_) => _screen(label)));
}

void main() {
  testWidgets('cây PHẲNG: .go() tự gỡ route mệnh lệnh', (tester) async {
    final router = GoRouter(
      initialLocation: '/lesson',
      routes: [
        GoRoute(path: '/lesson', builder: (_, __) => _screen('lesson')),
        GoRoute(path: '/roadmap', builder: (_, __) => _screen('roadmap')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    _push(tester.element(find.text('lesson')), 'habit-suggest');
    await tester.pumpAndSettle();
    expect(find.text('habit-suggest'), findsOneWidget);

    router.go('/roadmap');
    await tester.pumpAndSettle();

    expect(find.text('habit-suggest'), findsNothing);
    expect(find.text('roadmap'), findsOneWidget);
  });

  testWidgets(
    'cây CÓ SHELL (như app thật): .go() vào nhánh shell KHÔNG gỡ route mệnh lệnh',
    (tester) async {
      // Hình dạng thật: courseRoadmap nằm TRONG StatefulShellRoute
      // (routes_shell.dart), còn HabitSuggestPage được push lên root navigator
      // — tức nằm TRÊN cả cái shell.
      final router = GoRouter(
        navigatorKey: _rootKey,
        initialLocation: '/lesson',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => shell,
            branches: [
              StatefulShellBranch(
                navigatorKey: _shellKey,
                routes: [
                  GoRoute(path: '/lesson', builder: (_, __) => _screen('lesson')),
                  GoRoute(path: '/roadmap', builder: (_, __) => _screen('roadmap')),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      _push(tester.element(find.text('lesson')), 'habit-suggest');
      await tester.pumpAndSettle();
      expect(find.text('habit-suggest'), findsOneWidget);

      // Đúng cái openCourseRoadmapFromCoach làm, rồi nó trả true.
      router.go('/roadmap');
      await tester.pumpAndSettle();

      expect(
        find.text('habit-suggest'),
        findsOneWidget,
        reason: 'overlay root sống sót qua .go() vào nhánh shell — người gọi PHẢI tự pop',
      );
    },
  );

  testWidgets('cây CÓ SHELL: pop sau .go() mới thật sự tới roadmap', (tester) async {
    final router = GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/lesson',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => shell,
          branches: [
            StatefulShellBranch(
              navigatorKey: _shellKey,
              routes: [
                GoRoute(path: '/lesson', builder: (_, __) => _screen('lesson')),
                GoRoute(path: '/roadmap', builder: (_, __) => _screen('roadmap')),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final navigator = Navigator.of(tester.element(find.text('lesson')), rootNavigator: true);
    navigator.push<void>(MaterialPageRoute(builder: (_) => _screen('habit-suggest')));
    await tester.pumpAndSettle();

    router.go('/roadmap');
    if (navigator.canPop()) navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('habit-suggest'), findsNothing);
    expect(find.text('roadmap'), findsOneWidget);
  });
}
