import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// Cửa sổ ngày của chế độ "mỗi lần mở app".
///
/// Chế độ này trước đây chạy vô thời hạn, biến nó thành thuế vĩnh viễn đánh vào
/// mọi người chưa trả tiền chứ không còn là lời mời chào đón. Nay nó có cửa sổ
/// như chế độ kia, nhưng neo vào NGÀY TẠO TÀI KHOẢN chứ không phải habit đầu
/// tiên — habit đầu tiên chính là thứ chế độ này sinh ra để khỏi phải chờ.
///
/// Số học ngày tháng là đúng thứ `flutter analyze` không nhìn thấy.
class _FakeLocal implements MonetizationLocalDataSource {
  int? lastShownMs;

  @override
  Future<int?> getGiftLastShownEpochMs() async => lastShownMs;

  @override
  Future<void> setGiftLastShownEpochMs(int epochMs) async => lastShownMs = epochMs;

  // Lịch chỉ đọc ba mốc; phần còn lại của interface không dính tới cửa sổ.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeLocal local;
  late GiftPopupSchedule schedule;

  DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

  setUp(() {
    local = _FakeLocal();
    schedule = GiftPopupSchedule(local);
  });

  group('cửa sổ của chế độ mỗi-lần-mở-app', () {
    test('NGÀY ĐĂNG KÝ vẫn hiện — đây là chỗ khác chế độ 1 lần/ngày', () async {
      expect(
        await schedule.canShowEveryOpen(accountCreatedAt: daysAgo(0), windowDays: 7),
        isTrue,
      );
    });

    test('đúng ngày cuối cửa sổ vẫn hiện', () async {
      expect(
        await schedule.canShowEveryOpen(accountCreatedAt: daysAgo(7), windowDays: 7),
        isTrue,
      );
    });

    test('qua cửa sổ một ngày là thôi', () async {
      expect(
        await schedule.canShowEveryOpen(accountCreatedAt: daysAgo(8), windowDays: 7),
        isFalse,
      );
    });

    test('cửa sổ đi theo cấu hình, không phải hằng số 7', () async {
      expect(
        await schedule.canShowEveryOpen(accountCreatedAt: daysAgo(3), windowDays: 2),
        isFalse,
      );
      expect(
        await schedule.canShowEveryOpen(accountCreatedAt: daysAgo(3), windowDays: 30),
        isTrue,
      );
    });

    test('chưa đọc được ngày tạo thì để MỞ, không chặn', () async {
      // Profile chưa nạp xong là chuyện của mình, không phải của người đọc.
      expect(await schedule.canShowEveryOpen(accountCreatedAt: null), isTrue);
    });

    test('ngày tạo ở tương lai (đồng hồ lệch) vẫn cho hiện', () async {
      expect(
        await schedule.canShowEveryOpen(
          accountCreatedAt: DateTime.now().add(const Duration(days: 3)),
          windowDays: 7,
        ),
        isTrue,
      );
    });

    test('trong cửa sổ nhưng chưa đủ giãn cách thì vẫn không hiện', () async {
      local.lastShownMs =
          DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;

      expect(
        await schedule.canShowEveryOpen(
          minGapMinutes: 30,
          accountCreatedAt: daysAgo(1),
          windowDays: 7,
        ),
        isFalse,
      );
    });

    test('hết cửa sổ thì giãn cách không cứu được — cửa sổ chặn trước', () async {
      local.lastShownMs = null; // chưa hiện lần nào, giãn cách cho qua

      expect(
        await schedule.canShowEveryOpen(
          minGapMinutes: 0,
          accountCreatedAt: daysAgo(99),
          windowDays: 7,
        ),
        isFalse,
      );
    });
  });
}
