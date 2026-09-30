import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../support/test_di.dart';

/// Nhịp gõ từng chữ của bong bóng xem trước.
///
/// Server đẩy từng CỤM — Gemini trả mấy token một lần — nên nếu không có lớp
/// này thì chữ hiện theo nhúm, giật cục. Cả phần logic ở đây là thời gian, mà
/// `flutter analyze` không thấy được thời gian; chỉ có `pump` thấy.
void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  Widget buildSubject(
    String streamingText, {
    List<CoachMessage> messages = const [],
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => TranslationProvider(
        child: MaterialApp(home: Scaffold(body: child)),
      ),
      child: CoachMessageList(
        messages: messages,
        typing: true,
        streamingText: streamingText,
      ),
    );
  }

  /// Chữ đang thật sự hiện trên màn hình, ghép lại.
  String shownText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .join();

  group('bong bóng gõ từng chữ', () {
    testWidgets('không đổ cả cụm ra một lúc — chữ hiện dần', (tester) async {
      const line = 'Nghe mệt thật đấy bạn ạ, chuyện này kéo dài lâu chưa';
      await tester.pumpWidget(buildSubject(line));

      await tester.pump(const Duration(milliseconds: 32));
      final early = shownText(tester);

      await tester.pump(const Duration(milliseconds: 200));
      final later = shownText(tester);

      expect(early.length, lessThan(line.length));
      expect(later.length, greaterThan(early.length));

      // Để máy gõ chạy hết — timer tự huỷ khi gõ xong, y như lúc chạy thật.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('gõ xong thì ra ĐÚNG nguyên văn, không thiếu không thừa', (tester) async {
      const line = 'Mình hiểu rồi. Sáng nay có chuyện gì trước đó không?';
      await tester.pumpWidget(buildSubject(line));

      await tester.pump(const Duration(seconds: 3));

      expect(shownText(tester), contains(line));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('tồn đọng nhiều thì gõ nhanh hơn — không để đáp REST về lúc còn gõ dở', (tester) async {
      // Hai câu cùng độ dài nhịp gõ, một câu dài gấp bội: câu dài phải hiện
      // được TỈ LỆ nhiều hơn trong cùng một khoảng thời gian, chứ không phải
      // cùng số chữ — đó chính là phần tự bắt kịp.
      const short = 'Ừ mình nghe đây nhé bạn ơi';
      final long = List.filled(12, short).join(' ');

      await tester.pumpWidget(buildSubject(short));
      await tester.pump(const Duration(milliseconds: 160));
      final shortShown = shownText(tester).length;
      await tester.pump(const Duration(seconds: 5));

      await tester.pumpWidget(buildSubject(long));
      await tester.pump(const Duration(milliseconds: 160));
      final longShown = shownText(tester).length;
      await tester.pump(const Duration(seconds: 5));

      expect(longShown, greaterThan(shortShown));
    });

    testWidgets('lượt mới thì gõ LẠI TỪ ĐẦU, không gõ tiếp vào câu đã biến mất', (tester) async {
      await tester.pumpWidget(buildSubject('Câu của lượt trước, khá là dài dòng'));
      await tester.pump(const Duration(milliseconds: 300));

      // Chữ mới không nối tiếp chữ cũ = sang lượt khác.
      await tester.pumpWidget(buildSubject('Chuyện khác hẳn'));
      await tester.pump(const Duration(milliseconds: 16));

      final shown = shownText(tester);
      expect(shown, isNot(contains('lượt trước')));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('chưa có chữ nào thì ba chấm đứng nguyên — hai thứ không cùng hiện', (tester) async {
      await tester.pumpWidget(buildSubject(''));
      await tester.pump();

      expect(shownText(tester), isEmpty);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('bong bóng THẬT cũng gõ, không đổ ra nguyên cục', (tester) async {
      const line = 'Câu trả lời thật về bằng REST, dài vừa đủ để thấy nó gõ dần';
      await tester.pumpWidget(buildSubject(''));
      await tester.pump();

      // Đúng MỘT bong bóng mới = Coach vừa nói ra nó.
      await tester.pumpWidget(
        buildSubject('', messages: const [CoachMessage(isCoach: true, text: line)]),
      );
      await tester.pump(const Duration(milliseconds: 32));

      final early = shownText(tester);
      expect(early, isNotEmpty);
      expect(early.length, lessThan(line.length));

      await tester.pump(const Duration(seconds: 3));
      expect(shownText(tester), contains(line));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('xem trước sang bong bóng thật thì gõ TIẾP, không gõ lại từ đầu', (tester) async {
      const full = 'Nghe mệt thật. Sáng nay có chuyện gì trước đó không?';
      const previewed = 'Nghe mệt thật. ';

      await tester.pumpWidget(buildSubject(previewed));
      await tester.pump(const Duration(seconds: 2));
      final afterPreview = shownText(tester).length;
      expect(afterPreview, greaterThan(0));

      // Đáp REST về: cùng câu đó nhưng đủ, và phần xem trước bị xoá.
      await tester.pumpWidget(
        buildSubject('', messages: const [CoachMessage(isCoach: true, text: full)]),
      );
      await tester.pump();

      // Không tụt về 0 — đó chính là cái "gõ lại từ đầu" phải tránh.
      expect(shownText(tester).length, greaterThanOrEqualTo(afterPreview));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('lịch sử phát lại KHÔNG gõ — phải có sẵn ngay khi mở sheet', (tester) async {
      const history = [
        CoachMessage(isCoach: true, text: 'Dòng cũ thứ nhất của phiên hôm qua'),
        CoachMessage(isCoach: false, text: 'Người đọc trả lời'),
        CoachMessage(isCoach: true, text: 'Dòng cũ thứ ba, cũng khá dài dòng'),
      ];

      await tester.pumpWidget(buildSubject(''));
      await tester.pump();
      // Nhiều bong bóng cùng lúc = lịch sử, không phải Coach đang nói.
      await tester.pumpWidget(buildSubject('', messages: history));
      await tester.pump();

      final shown = shownText(tester);
      for (final message in history) {
        expect(shown, contains(message.text));
      }
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
