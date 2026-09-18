part of '../../../onboard_v2.dart';

/// Lỗi tại chỗ + nút Thử lại, dùng chung cho mọi bước onboarding có dữ liệu
/// server (tuổi, taxonomy câu 1, danh sách vấn đề rỗng…). Trước đây là
/// `_InlineError` riêng của trang tuổi.
class OnboardV2InlineError extends StatelessWidget {
  const OnboardV2InlineError({super.key, required this.message, required this.onRetry, this.retryLabel});

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          AppText(
            message,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
          ),
          TextButton(
            onPressed: () {
              AppHaptic.select();
              onRetry();
            },
            child: Text(retryLabel ?? context.l10n.onboarding.onboardingV2RetryCta),
          ),
        ],
      ),
    );
  }
}
