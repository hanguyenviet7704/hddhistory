part of '../../profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _hasTrackedView = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;

  @override
  void initState() {
    super.initState();
    context.read<IapCubit>().loadIapProducts();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  void _trackView() {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackSettingScrView();
    _hasTrackedView = true;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _hasTrackedScroll) return;
    if (_scrollController.position.pixels <= 0) return;
    AppService.instance.appTrackingService.trackSettingScroll();
    _hasTrackedScroll = true;
  }

  Future<void> _onRefresh() async {
    context.read<ProfileCubit>().loadUser();
    context.read<AchievenmentProgressCubit>().loadAllAchievenmentResponses();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
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
            buildWhen: (previous, current) => previous.status != current.status || previous.achievenments != current.achievenments,
            builder: (context, state) {
              final bool isLoading = state.status == AchievenmentProgressStatus.loading && state.achievenments.isEmpty;
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  controller: _scrollController,
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
                          onUpgrade: () {
                            AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.profile);
                            const PaywallRoute().push(context);
                          },
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
