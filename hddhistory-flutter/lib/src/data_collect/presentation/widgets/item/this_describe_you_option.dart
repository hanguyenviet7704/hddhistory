part of '../../../data_collect.dart';

class ThisDescribeYouOption extends StatelessWidget {
  final String title;
  final bool isSelectedYes;
  final bool isSelectedNo;
  final Function(bool) onYesChanged;
  final Function(bool) onNoChanged;

  const ThisDescribeYouOption({
    super.key,
    required this.title,
    required this.isSelectedYes,
    required this.isSelectedNo,
    required this.onYesChanged,
    required this.onNoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          AppText(
            title,
            maxLines: 10,
            expandFlex: 1,
            style: AppStyle.text16.copyWith(
              color: const Color(0xFF364152), // Text/Secondary
              fontWeight: FontWeight.w500,
            ),
          ),

          20.horizontalSpace,

          // Yes/No Options
          Row(
            children: [
              // Yes Option
              GestureDetector(
                onTap: () {
                  AppHaptic.select();
                  onYesChanged(!isSelectedYes);
                },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelectedYes
                        ? const Color(0xFFFDEAE7) // Background/Error
                        : const Color(0xFFF5F7FB), // Background/Gray
                    border: Border.all(
                      color: isSelectedYes
                          ? const Color(0xFFDF2917) // Border/Error
                          : const Color(0xFFE3E8EF), // Border/Secondary
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isSelectedYes ? const Color(0xFFDF2917) : const Color(0xFF7F8EA4), // Text/Tertiary
                    size: 28.sp,
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // No Option
              GestureDetector(
                onTap: () {
                  AppHaptic.select();
                  onNoChanged(!isSelectedNo);
                },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelectedNo
                        ? const Color(0xFFEAFFEF) // Background/Success
                        : const Color(0xFFF5F7FB), // Background/Gray
                    border: Border.all(
                      color: isSelectedNo
                          ? const Color(0xFF41AE8C) // Brand/Brand/Secondary
                          : const Color(0xFFE3E8EF), // Border/Secondary
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: isSelectedNo ? const Color(0xFF41AE8C) : const Color(0xFF7F8EA4), // Text/Tertiary
                      size: 28.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
