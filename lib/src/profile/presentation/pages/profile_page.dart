part of '../../profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<IapCubit>().loadIapProducts();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
  }

  Future<void> _onRefresh() async {
    context.read<ProfileCubit>().loadUser();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: CupertinoScaffold(
        topRadius: const Radius.circular(24),
        transitionBackgroundColor: AppCustomColor.backgroundWhite,
        body: SafeBody(
          child: BlocBuilder<AchievenmentProgressCubit, AchievenmentProgressState>(
            buildWhen: (previous, current) =>
                previous.status != current.status || previous.achievenments != current.achievenments,
            builder: (context, state) {
              final bool isLoading =
                  state.status == AchievenmentProgressStatus.loading && state.achievenments.isEmpty;
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
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

                    UserAchievementList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
