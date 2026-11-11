part of '../../data_collect.dart';

class DataCollectPage extends StatefulWidget {
  const DataCollectPage({super.key});

  @override
  State<DataCollectPage> createState() => _DataCollectPageState();
}

class _DataCollectPageState extends State<DataCollectPage> {
  DataCollectStep? _lastTrackedStep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackStepView(context.read<DataCollectCubit>().state.currentStep);
    });
  }

  void _trackStepView(DataCollectStep step) {
    if (_lastTrackedStep == step) return;
    _lastTrackedStep = step;

    switch (step) {
      case DataCollectStep.collectName:
        AppService.instance.appTrackingService.trackObdNameScrView();
        break;
      case DataCollectStep.collectAge:
        AppService.instance.appTrackingService.trackObdAgeScrView();
        break;
      case DataCollectStep.collectGender:
        AppService.instance.appTrackingService.trackObdGenderScrView();
        break;
      case DataCollectStep.collectLearningGoal:
        AppService.instance.appTrackingService.trackObdLearningGoalScrView();
        break;
      case DataCollectStep.collectCategoriesWantToMaster:
        AppService.instance.appTrackingService.trackObdCategoryScrView();
        break;
      case DataCollectStep.collectLearningStrugger:
        AppService.instance.appTrackingService.trackObdStrugglesScrView();
        break;
      case DataCollectStep.motivateHowToLearn:
        AppService.instance.appTrackingService.trackObdHowToLearnScrView();
        break;
      case DataCollectStep.collectDailyLearningGoal:
        AppService.instance.appTrackingService.trackObdDailyTimeScrView();
        break;
      case DataCollectStep.collectComfortableLearningTime:
        AppService.instance.appTrackingService.trackObdLearningTimeScrView();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DataCollectCubit, DataCollectState>(
      listenWhen: (previous, current) => previous.currentStep != current.currentStep,
      listener: (context, state) {
        _trackStepView(state.currentStep);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              ProgressBar(),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const StepBody(),
                ),
              ),

              // Bottom CTA Button
              const ContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class StepBody extends StatelessWidget {
  const StepBody({super.key});

  @override
  Widget build(BuildContext context) {
    final currentStep = context.select((DataCollectCubit cubit) => cubit.state.currentStep);
    return switch (currentStep) {
      DataCollectStep.collectName => const NameCollectBody(),
      DataCollectStep.collectAge => const AgeCollectBody(),
      DataCollectStep.collectGender => const GenderCollectBody(),
      DataCollectStep.collectLearningGoal => const LearningGoalBody(),
      DataCollectStep.collectCategoriesWantToMaster => const CategoriesWantToMasterBody(),
      DataCollectStep.collectLearningStrugger => const LearningStruggerBody(),
      DataCollectStep.motivateHowToLearn => const HowToLearnBody(),
      DataCollectStep.collectDailyLearningGoal => const DailyLearningGoalBody(),
      DataCollectStep.collectComfortableLearningTime => ComfortableLearningTimeBody(),
    };
  }
}
