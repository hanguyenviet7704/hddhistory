part of '../../feedback.dart';

class FeedbackCommentField extends StatefulWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final double height;

  const FeedbackCommentField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.height = 120,
  });

  @override
  State<FeedbackCommentField> createState() => _FeedbackCommentFieldState();
}

class _FeedbackCommentFieldState extends State<FeedbackCommentField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant FeedbackCommentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
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
    return Container(
      height: widget.height.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppCustomColor.borderSecondary, width: 1.w),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textSecondary,
          height: 1.75,
        ),
        cursorColor: AppCustomColor.brandPrimary,
        decoration: InputDecoration.collapsed(
          hintText: widget.hint,
          hintStyle: AppStyle.text14.copyWith(
            color: AppCustomColor.textQuaternary,
            height: 1.75,
          ),
        ),
      ),
    );
  }
}
