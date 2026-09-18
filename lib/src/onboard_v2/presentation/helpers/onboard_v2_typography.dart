part of '../../onboard_v2.dart';

/// Kiểu tiêu đề của onboarding v3 theo Claude Design ("MeUp Onboarding v2").
/// Design để 24–26px tuỳ màn; các màn S7–S10 dùng 25px, đậm 700, giãn dòng
/// 1.25 — khác hẳn `text28/w800/1.4` mà các màn cũ đang dùng.
TextStyle onboardV2HeadingStyle({double fontSize = 25}) {
  return AppStyle.text24.copyWith(
    fontSize: fontSize.sp,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
}
