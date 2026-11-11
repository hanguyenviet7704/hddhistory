part of '../../../data_collect.dart';

class CategoriesWantToMasterBody extends StatelessWidget {
  const CategoriesWantToMasterBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataCollectSectionHeader(
              title: context.l10n.onboarding.onboardingChooseCategoryTitle,
              subtitle: context.l10n.onboarding.onboardingChooseCategorySubtitle,
            ),
            Spacer(),

            // Topic Options
            const CategoriesWantToMasterBodyOptions(),
          ],
        );
      },
    );
  }
}

class CategoriesWantToMasterBodyOptions extends StatelessWidget {
  const CategoriesWantToMasterBodyOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.onboardData != current.onboardData || previous.selectedCategoriesWantToMaster != current.selectedCategoriesWantToMaster,
      builder: (context, state) {
        final cubit = context.read<DataCollectCubit>();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: state.onboardData.categoryWantToMaster.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          itemBuilder: (context, index) {
            final topic = state.onboardData.categoryWantToMaster[index];
            return DataCollectOptionTile(
              option: topic,
              isSelected: state.selectedCategoriesWantToMaster.contains(topic),
              onTap: () {
                AppService.instance.appTrackingService.trackObdCategoryClick();
                cubit.selectCategoryWantToMaster(topic);
              },
              type: DataCollectOptionType.checkbox,
            );
          },
        );
      },
    );
  }
}
