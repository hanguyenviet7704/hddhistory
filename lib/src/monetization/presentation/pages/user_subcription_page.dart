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
    context.read<ProfileCubit>().loadUserIapSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeBody(
        child: Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 12.h, bottom: 20.h),
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final hasSubscription = state.user.iapSubscriptions.isNotEmpty;
              final subscription = hasSubscription ? state.user.iapSubscriptions.first : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserSubscriptionHeader(onBack: context.back),
                  12.verticalSpace,
                  _CurrentPlanRow(
                    actionLabel: hasSubscription ? context.l10n.monetization.manageChangeCta : context.l10n.monetization.manageUpgradeCta,
                    onAction: () {
                      AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.manageSubscription);
                      const PaywallRoute().replace(context);
                    },
                  ),
                  12.verticalSpace,
                  hasSubscription ? UserSubscriptionActiveCard(subscription: subscription!) : const UserSubscriptionEmptyState(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanRow extends StatelessWidget {
  const _CurrentPlanRow({required this.actionLabel, required this.onAction});

  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          context.l10n.monetization.manageCurrentPlan,
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w600,
            color: AppCustomColor.textSecondary,
            height: 1.75,
          ),
        ),
        const Spacer(),
        if (kDebugMode)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptic.select();
              onAction();
            },
            child: AppText(
              actionLabel,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.brandPrimary,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
