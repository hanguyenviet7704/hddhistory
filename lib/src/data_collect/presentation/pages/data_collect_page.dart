part of '../../data_collect.dart';

class DataCollectPage extends StatelessWidget {
  const DataCollectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<DataCollectCubit>(),
      child: BlocBuilder<DataCollectCubit, DataCollectState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Progress Bar
                  const ProgressBar(
                    currentStep: 1,
                    totalSteps: 10,
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
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
                            child: _buildBody(state),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom CTA Button
                  Container(
                    padding: EdgeInsets.all(20.w),
                    child: AppButton.primary(
                      onPressed: () {
                        // Add continue logic here
                      },
                      fullWidthBtn: true,
                      height: 54.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E8EF), // Neutral/200
                        borderRadius: BorderRadius.circular(1000.r),
                      ),
                      child: AppText(
                        'Continue',
                        style: AppStyle.textBold16.copyWith(
                          color: const Color(0xFF7F8EA4), // Text/Tertiary
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(DataCollectState state) {
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
