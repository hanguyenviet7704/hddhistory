part of '../../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  CourseCubit() : super(CourseState.initial());

  void setCourses(List<CourseEntity> courses) => emit(state.copyWith(courses: courses));

  void selectTab(int index) => emit(state.copyWith(selectedTabIndex: index));

  void setAllCourseSource(String source) => emit(state.copyWith(allCourseSource: source));
}
