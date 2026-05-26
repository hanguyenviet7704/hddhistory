part of '../../daily_warm_up.dart';

class DailyWarmUpArrangeBody extends StatelessWidget {
  const DailyWarmUpArrangeBody({
    super.key,
    required this.state,
    required this.question,
    required this.onSetOrderedOptionIds,
  });

  final DailyWarmUpState state;
  final QuestionEntity question;
  final ValueChanged<List<int>> onSetOrderedOptionIds;

  @override
  Widget build(BuildContext context) {
    final options = _dailyWarmUpOptions(question);
    final orderedOptions = _orderedOptions(options);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) => child,
        itemCount: orderedOptions.length,
        onReorderItem: (oldIndex, newIndex) {
          final ids = orderedOptions.map((option) => option.id).toList();
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          onSetOrderedOptionIds(ids);
        },
        itemBuilder: (context, index) {
          final option = orderedOptions[index];
          return Padding(
            key: ValueKey('daily-warm-up-arrange-${option.id}'),
            padding: EdgeInsets.only(bottom: 10.h),
            child: ArrangeSequenceAnswerCard(
              text: option.labelText,
              index: index,
              state: _answerState(orderedOptions, index),
              dragEnabled: state.latestResult == null,
            ),
          );
        },
      ),
    );
  }

  List<OptionEntity> _orderedOptions(List<OptionEntity> options) {
    if (state.orderedOptionIds.isEmpty) return options;
    final byId = {for (final option in options) option.id: option};
    final ordered = <OptionEntity>[];
    for (final id in state.orderedOptionIds) {
      final option = byId[id];
      if (option != null) ordered.add(option);
    }
    for (final option in options) {
      if (!state.orderedOptionIds.contains(option.id)) ordered.add(option);
    }
    return ordered;
  }

  ArrangeAnswerState _answerState(List<OptionEntity> orderedOptions, int index) {
    final result = state.latestResult;
    if (result == null) return ArrangeAnswerState.normal;
    if (index >= orderedOptions.length || index >= result.correctOptionIds.length) return ArrangeAnswerState.incorrect;
    return orderedOptions[index].id == result.correctOptionIds[index] ? ArrangeAnswerState.correct : ArrangeAnswerState.incorrect;
  }
}
