// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/config/services/services.dart';

/// Nhánh A/B nội dung được nhớ theo courseId. Dán nhánh của khoá A lên event
/// của khoá B là làm bẩn số liệu theo cách rất khó truy, nên guard này là chỗ
/// đáng test nhất của cả phần Flutter.
void main() {
  final tracker = ContentExperimentTracker.instance;

  setUp(tracker.reset);

  test('chưa nhớ gì thì không đóng dấu', () {
    expect(tracker.paramsFor('course-1'), isEmpty);
  });

  test('đóng dấu key và arm cho đúng khoá đã nhớ', () {
    tracker.remember(courseId: 'course-1', key: 'noidung_2026_09', arm: 'B');

    expect(tracker.paramsFor('course-1'), {
      'content_experiment_key': 'noidung_2026_09',
      'content_variant': 'B',
    });
  });

  test('KHÔNG đóng dấu cho khoá khác', () {
    tracker.remember(courseId: 'course-1', key: 'noidung_2026_09', arm: 'B');

    expect(tracker.paramsFor('course-2'), isEmpty);
  });

  /// Khoá không nằm trong đợt: server trả `contentExperiment: null`, nên
  /// key/arm về đây là null — và không được đóng dấu gì.
  test('khoá không trong đợt thì không đóng dấu', () {
    tracker.remember(courseId: 'course-1', key: null, arm: null);

    expect(tracker.paramsFor('course-1'), isEmpty);
  });

  test('chuỗi rỗng cũng coi như không có đợt', () {
    tracker.remember(courseId: 'course-1', key: '', arm: '');

    expect(tracker.paramsFor('course-1'), isEmpty);
  });

  test('đổi khoá thì chỉ khoá mới được đóng dấu', () {
    tracker.remember(courseId: 'course-1', key: 'k1', arm: 'A');
    tracker.remember(courseId: 'course-2', key: 'k1', arm: 'B');

    expect(tracker.paramsFor('course-1'), isEmpty);
    expect(tracker.paramsFor('course-2'), {
      'content_experiment_key': 'k1',
      'content_variant': 'B',
    });
  });

  test('courseId rỗng thì không đóng dấu và không ghi đè', () {
    tracker.remember(courseId: 'course-1', key: 'k1', arm: 'A');
    tracker.remember(courseId: '', key: 'k2', arm: 'B');

    expect(tracker.paramsFor('course-1'), {
      'content_experiment_key': 'k1',
      'content_variant': 'A',
    });
    expect(tracker.paramsFor(''), isEmpty);
  });
}
