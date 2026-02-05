part of '../../../data_collect.dart';

class TopicOption extends StatelessWidget {
  final OnboardOptionEntity value;
  final bool isSelected;
  final Function(OnboardOptionEntity?) onChanged;

  const TopicOption({
    super.key,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DataCollectOptionTile(
      option: value,
      isSelected: isSelected,
      onTap: () => onChanged(value),
      type: DataCollectOptionType.checkbox,
      titleStyle: AppStyle.text14.copyWith(fontWeight: FontWeight.w500),
      subtitle: value.title.text.isNotEmpty ? value.title.text : null,
      subtitleStyle: AppStyle.text12.copyWith(fontWeight: FontWeight.w400),
    );
  }
}
