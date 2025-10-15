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
                      child: DataCollectBody(
                        state: state,
                        currentStep: 1,
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
}
