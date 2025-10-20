part of '../../data_collect.dart';

class DataCollectSummaryPage extends StatelessWidget {
  const DataCollectSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, bool>(
      selector: (state) => state.analysisComplete,
      builder: (context, analysisComplete) {
        if (!analysisComplete) return const AnalysisState();
        return const UserDataState();
      },
    );
  }
}
