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

/// Dòng chữ phụ dưới tiêu đề (phụ đề, câu gợi ý chọn). Design để 14px, đậm 500,
/// màu xám nhạt — trước đây app dùng 16px màu chữ phụ đậm hơn nên nhìn to và
/// nặng hơn hẳn bản vẽ.
TextStyle onboardV2SubtitleStyle({double fontSize = 14}) {
  return AppStyle.text14.copyWith(
    fontSize: fontSize.sp,
    color: AppCustomColor.onboardMutedLabel,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}

/// Nhãn nhỏ viết hoa ở đầu màn (eyebrow) và nhãn nhóm. Design: 11px, đậm 800,
/// giãn chữ nhẹ.
TextStyle onboardV2EyebrowStyle({double letterSpacing = 0.22}) {
  return AppStyle.text12.copyWith(
    fontSize: 11.sp,
    color: AppCustomColor.onboardMutedLabel,
    fontWeight: FontWeight.w800,
    letterSpacing: letterSpacing,
    height: 1.4,
  );
}
