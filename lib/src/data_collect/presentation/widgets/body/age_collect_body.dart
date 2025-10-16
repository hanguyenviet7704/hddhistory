part of '../../../data_collect.dart';

class AgeCollectBody extends StatelessWidget {
  final DataCollectState state;
  final int currentStep;

  const AgeCollectBody({
    super.key,
    required this.state,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 2:
        return _buildStep2();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildStep2() {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AppText(
              "What's your age?",
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20.h),

            // Age Range Options
            Expanded(
              child: _buildAgeOptions(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return Center(
      child: AppText(
        'Step content not implemented yet',
        style: AppStyle.text16,
      ),
    );
  }

  Widget _buildAgeOptions(BuildContext context, DataCollectState state) {
    final cubit = context.read<DataCollectCubit>();

    return Column(
      children: [
        _AgeOption(
          title: '17 or younger',
          value: '17_or_younger',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        _AgeOption(
          title: '18-24',
          value: '18-24',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        _AgeOption(
          title: '25-34',
          value: '25-34',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        _AgeOption(
          title: '35-44',
          value: '35-44',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
        SizedBox(height: 12.h),
        _AgeOption(
          title: '45 or older',
          value: '45_or_older',
          groupValue: state.selectedAgeRange ?? '25-34', // Default selected value
          onChanged: (value) {
            cubit.selectAgeRange(value!);
          },
        ),
      ],
    );
  }
}

class _AgeOption extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final Function(String?) onChanged;

  const _AgeOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF), // Brand/Primary or Border/Default
            width: 2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              title,
              style: AppStyle.text16.copyWith(
                color: isSelected
                    ? const Color(0xFF0D121C) // content/primary
                    : const Color(0xFF7F8EA4), // Text/Tertiary
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            _CustomRadio(
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRadio extends StatelessWidget {
  final bool isSelected;

  const _CustomRadio({
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.h,
      padding: EdgeInsets.all(2.w),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF462BF4) : Colors.white, // button/primary/default or white
          borderRadius: BorderRadius.circular(1200.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF462BF4) : const Color(0xFFE3E8EF), // button/primary/default or Border/Default
            width: 2.w,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 8.229.w,
                  height: 8.229.h,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
