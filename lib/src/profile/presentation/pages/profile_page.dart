part of '../../profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<IapCubit>().loadIapProducts();
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: CupertinoScaffold(
        topRadius: const Radius.circular(24),
        transitionBackgroundColor: AppCustomColor.backgroundWhite,
        body: SafeBody(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 48.h),
            physics: const BouncingScrollPhysics(),
            children: [
              SettingProfileCard(),
              24.verticalSpace,
              BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                selector: (state) => state.user,
                builder: (context, user) {
                  if (user.iapSubscriptions.isNotEmpty) return SizedBox.shrink();

                  return SettingPreminumCard(
                    onUpgrade: () => const PaywallRoute().push(context),
                  );
                },
              ),
              24.verticalSpace,
              AppText(
                'Achievements',
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
