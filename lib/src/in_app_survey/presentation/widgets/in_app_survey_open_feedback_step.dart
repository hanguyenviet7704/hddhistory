part of '../../in_app_survey.dart';

class InAppSurveyOpenFeedbackStep extends StatefulWidget {
  const InAppSurveyOpenFeedbackStep({
    super.key,
    required this.branch,
    required this.feedback,
    required this.onFeedbackChanged,
  });

  final InAppSurveyBranchEntity branch;
  final String feedback;
  final ValueChanged<String> onFeedbackChanged;

  @override
  State<InAppSurveyOpenFeedbackStep> createState() => _InAppSurveyOpenFeedbackStepState();
}

class _InAppSurveyOpenFeedbackStepState extends State<InAppSurveyOpenFeedbackStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.feedback);
  }

  @override
  void didUpdateWidget(covariant InAppSurveyOpenFeedbackStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.feedback,
        selection: TextSelection.collapsed(offset: widget.feedback.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InAppSurveyTitle(_surveyText(widget.branch.openQuestion.question)),
        24.verticalSpace,
        Semantics(
          textField: true,
          label: 'Survey feedback',
          child: TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 5,
            maxLength: 1000,
            onChanged: widget.onFeedbackChanged,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Maybe if MeUp...',
              hintStyle: AppStyle.text14.copyWith(color: _InAppSurveyColors.textTertiary, height: 1.75),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: _InAppSurveyColors.borderSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: _InAppSurveyColors.brandPrimary, width: 1.4),
              ),
            ),
            style: AppStyle.text14.copyWith(color: _InAppSurveyColors.textPrimary, height: 1.75),
          ),
        ),
      ],
    );
  }
}
