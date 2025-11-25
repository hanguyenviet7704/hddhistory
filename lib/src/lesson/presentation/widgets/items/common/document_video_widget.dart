part of '../../../../lesson.dart';

class DocumentVideoWidget extends StatelessWidget {
  final String url;
  final String thumbnail;
  const DocumentVideoWidget({super.key, required this.url, required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        16.verticalSpace,
        DCachedImage(url: url, width: double.infinity, borderRadius: BorderRadius.circular(16.r), fit: BoxFit.cover),
      ],
    );
  }
}