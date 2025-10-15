part of '../../../data_collect.dart';

class DataCollectBody extends StatelessWidget {
  final DataCollectState state;
  final int currentStep;

  const DataCollectBody({
    super.key,
    required this.state,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 1:
        return _buildStep1();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        AppText(
          'What should I call you?',
          style: AppStyle.textBold20.copyWith(
            color: const Color(0xFF364152), // Text/Secondary
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: 20.h),

        // Input Field
        const OnboardingInput(
          hintText: 'Enter your name',
        ),

        SizedBox(height: 20.h),

        // Existing content based on state
        Expanded(
          child: _buildStateContent(state),
        ),
      ],
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

  Widget _buildStateContent(DataCollectState state) {
    switch (state.status) {
      case DataCollectStatus.initial:
        return const SizedBox.shrink();
      case DataCollectStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DataCollectStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16.h),
              AppText(
                state.errorMessage ?? 'An error occurred',
                style: AppStyle.text16,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case DataCollectStatus.success:
        if (state.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE3E8EF), // Neutral/200
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          item.name,
                          style: AppStyle.textBold16.copyWith(
                            color: const Color(0xFF364152), // Text/Secondary
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          'Created: ${item.createdAt}',
                          style: AppStyle.text14.copyWith(
                            color: const Color(0xFF7F8EA4), // Text/Tertiary
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Add delete logic here
                    },
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}
