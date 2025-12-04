part of '../../monetization.dart';

class UserSubcriptionPage extends StatefulWidget {
  const UserSubcriptionPage({super.key});

  @override
  State<UserSubcriptionPage> createState() => _UserSubcriptionPageState();
}

class _UserSubcriptionPageState extends State<UserSubcriptionPage> {
  @override
  void initState() {
    super.initState();
    // Ensure subscription info is fresh.
    final profileCubit = context.read<ProfileCubit>();
    profileCubit.loadUserIapSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeBody(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserSubscriptionHeader(onBack: context.back),
              20.verticalSpace,
              Expanded(
                child: BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    final subscriptions = state.user.iapSubscriptions;
                    if (subscriptions.isEmpty) {
                      return UserSubscriptionEmptyState(
                        onUpgrade: () => const PaywallRoute().push(context),
                      );
                    }

                    final subscription = subscriptions.first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserSubscriptionActiveCard(subscription: subscription),
                        const Spacer(),
                        AppButton.primary(
                          fullWidthBtn: true,
                          height: 56.h,
                          child: t.monetization.manageChangeCta,
                          onPressed: () => const PaywallRoute().push(context),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
