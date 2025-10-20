part of '../../data_collect.dart';

class DataCollectSummaryPage extends StatelessWidget {
  const DataCollectSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<DataCollectCubit>().startAnalysis();
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        // Show loading/analysis state
        if (!state.analysisComplete) {
          return const AnalysisState();
        }

        // Show user data state
        return UserDataState(state: state);
      },
    );
  }
}
