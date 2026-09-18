part of '../../../onboard_v2.dart';

class OnboardV2ScreenShell extends StatelessWidget {
  const OnboardV2ScreenShell({
    super.key,
    required this.child,
    required this.cta,
    this.backgroundColor = AppCustomColor.backgroundWhite,
    this.header,
    this.scrollable = true,
  });

  final Widget child;
  final Widget cta;
  final Color backgroundColor;
  final Widget? header;

  /// Mặc định nội dung nằm trong vùng cuộn. Màn nào cần căn giữa theo chiều dọc
  /// (S9 đang tạo lộ trình) thì tắt đi, phần thân sẽ nhận trọn chiều cao còn
  /// lại và tự căn lấy.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: Column(
            children: [
              ?header,
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: child)
                    : child,
              ),
              cta,
            ],
          ),
        ),
      ),
    );
  }
}
