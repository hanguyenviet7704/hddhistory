part of '../../home.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.verticalSpace,
          // Greeting
          AppText(
            'Good morning,',
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.grey69,
            ),
          ),
          
        ],
      ),
    );
  }
}
