import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

/// Khi nào chip "Tiếp tục học" hiện.
///
/// Test này tồn tại vì một lỗi ẩn được rất lâu: quay lại Khám phá từ roadmap
/// thì chip biến mất và không bao giờ trở lại.
///
/// Nguyên nhân không nằm ở chip. `_backFromRoadmap` đặt lại `currentRouteName`
/// ở mọi nhánh trừ nhánh Khám phá, nên con trỏ kẹt ở `courseRoadmap`. Cái làm
/// nó vô hình suốt thời gian đó chính là cặp khẳng định dưới đây: trên
/// `courseRoadmap` thì `isPrimaryRoute` vẫn ĐÚNG — roadmap giữ thanh nav — nên
/// thứ duy nhất đọc tên route hồi ấy không hề đổi hình dạng. Chip là thứ đầu
/// tiên đọc nó trên đường này, và nó ẩn.
///
/// Nói cách khác: "nav vẫn hiện" KHÔNG chứng minh tên route đã đúng. Nếu bao
/// giờ có người sửa `primaryRouteNames` hay vị ngữ này, hai khẳng định đầu là
/// thứ giữ cho cái bẫy ấy không quay lại im lặng.
void main() {
  const inProgress = CourseEntity(
    id: 'c1',
    numberOfLesson: 10,
    numberOfLessonPassed: 3,
  );

  ProgressState withCourses(List<CourseEntity> courses) => ProgressState(
    myCoursesPageData: BasePageBreak<CourseEntity>(items: courses),
  );

  PageState onRoute(String name) => PageState(currentRouteName: name);

  group('shouldShowResumeChip', () {
    test('BẪY: roadmap vẫn là primary route — nav hiện không nghĩa là tên đúng', () {
      expect(onRoute(RouteNamed.courseRoadmap).isPrimaryRoute, isTrue);
    });

    test('nhưng chip thì ẩn trên roadmap — roadmap CHÍNH LÀ đích đến', () {
      expect(
        shouldShowResumeChip(
          onRoute(RouteNamed.courseRoadmap),
          withCourses([inProgress]),
        ),
        isFalse,
      );
    });

    test('quay lại Khám phá thì chip hiện lại — đây là lỗi được vá', () {
      expect(
        shouldShowResumeChip(onRoute(RouteNamed.course), withCourses([inProgress])),
        isTrue,
      );
    });

    test('ẩn trên màn đọc bài — ở đó nav cũng không có', () {
      expect(
        shouldShowResumeChip(onRoute(RouteNamed.lesson), withCourses([inProgress])),
        isFalse,
      );
    });

    test('không có khoá nào đang học dở thì không hiện, dù đứng ở đâu', () {
      expect(
        shouldShowResumeChip(onRoute(RouteNamed.course), withCourses(const [])),
        isFalse,
      );
    });

    test('khoá đã xong hoặc chưa bắt đầu đều không tính là "đang học dở"', () {
      const done = CourseEntity(id: 'c2', numberOfLesson: 5, numberOfLessonPassed: 5);
      const untouched = CourseEntity(id: 'c3', numberOfLesson: 5, numberOfLessonPassed: 0);

      expect(resumeCourseFor(withCourses([done, untouched])), isNull);
      expect(resumeCourseFor(withCourses([done, inProgress])), inProgress);
    });
  });
}
