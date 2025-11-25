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
          BlocSelector<UserCubit, UserState, String>(
            selector: (state) => state.user.name,
            builder: (context, username) {
              return AppText(
                context.text.home.homeGreetingTitle(username: username),
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.grey69,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
