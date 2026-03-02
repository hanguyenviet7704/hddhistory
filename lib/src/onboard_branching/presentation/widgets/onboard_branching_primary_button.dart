part of '../../onboard_branching.dart';

class OnboardBranchingPrimaryButton extends StatelessWidget {
  const OnboardBranchingPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: canTap ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canTap ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
          foregroundColor: canTap ? Colors.white : const Color(0xFF7F8EA4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : AppText(
                text,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: canTap ? Colors.white : const Color(0xFF7F8EA4),
                ),
              ),
      ),
    );
  }
}
