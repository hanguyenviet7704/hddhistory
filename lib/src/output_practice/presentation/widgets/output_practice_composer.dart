part of '../../output_practice.dart';

class OutputPracticeComposer extends StatelessWidget {
  const OutputPracticeComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, MediaQuery.viewPaddingOf(context).bottom + 12.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00F4E6DE),
            Color(0xFFF4E6DE),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: placeholder,
                  border: InputBorder.none,
                  hintStyle: AppStyle.text14.copyWith(
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                  ),
                ),
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.75,
                ),
              ),
            ),
          ),
          12.horizontalSpace,
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFF554FF0) : const Color(0xFFAAB8CD),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 18.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
