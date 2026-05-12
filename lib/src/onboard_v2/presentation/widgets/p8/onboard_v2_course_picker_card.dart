part of '../../../onboard_v2.dart';

class OnboardV2CoursePickerCard extends StatelessWidget {
  const OnboardV2CoursePickerCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final image = course.image.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 260.w,
        height: 260.w,
        color: AppCustomColor.borderBrand,
        child: image.isNotEmpty
            ? DCachedImage(
                url: image,
                width: 260.w,
                height: 260.w,
                fit: BoxFit.cover,
              )
            : Center(
                child: Icon(Icons.menu_book_rounded, size: 64.w, color: AppCustomColor.brandPrimary),
              ),
      ),
    );
  }
}
