part of '../../../data_collect.dart';

class NativeLanguageBody extends StatelessWidget {
  const NativeLanguageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Spacer(),
            AppText(
              "Are you a native\nEnglish speaker?",
              style: AppStyle.textBold20.copyWith(
                color: const Color(0xFF364152), // Text/Secondary
                fontWeight: FontWeight.w500,
              ),
              maxLines: 10,
              textAlign: TextAlign.center,
            ),
            Spacer(),
            // Native Language Options
            NativeLanguageOptions(),
          ],
        );
      },
    );
  }
}

class NativeLanguageOptions extends StatelessWidget {
  const NativeLanguageOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, bool?>(
      selector: (state) => state.isNativeEnglishSpeaker,
      builder: (context, isNativeEnglishSpeaker) {
        final cubit = context.read<DataCollectCubit>();
        return Row(
          children: [
            // Yes Option
            Expanded(
              child: GestureDetector(
                onTap: () => cubit.selectNativeEnglishSpeaker(true),
                child: Container(
                  height: 92.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isNativeEnglishSpeaker == true ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
                    border: Border.all(
                      color: isNativeEnglishSpeaker == true
                          ? const Color(0xFF554FF0) // Brand/Primary
                          : const Color(0xFFE3E8EF), // Border/Secondary
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      // Icon
                      Icon(
                        Icons.check_rounded,
                        color: const Color(0xFF3A9377),
                        size: 24.sp,
                      ),
                      16.verticalSpace,
                      // Text
                      AppText(
                        'Yes',
                        style: AppStyle.text16.copyWith(
                          color: isNativeEnglishSpeaker == true
                              ? const Color(0xFF0D121C) // content/primary
                              : const Color(0xFF7F8EA4), // Text/Tertiary
                          fontWeight: isNativeEnglishSpeaker == true ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            16.horizontalSpace,
            // No Option
            Expanded(
              child: GestureDetector(
                onTap: () => cubit.selectNativeEnglishSpeaker(false),
                child: Container(
                  height: 92.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isNativeEnglishSpeaker == false ? Colors.white : const Color(0xFFF5F7FB), // Background/Gray
                    border: Border.all(
                      color: isNativeEnglishSpeaker == false
                          ? const Color(0xFF554FF0) // Brand/Primary
                          : const Color(0xFFE3E8EF), // Border/Secondary
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      // Icon
                      Icon(
                        Icons.close_rounded,
                        color: const Color(0xFFD63327),
                        size: 24.sp,
                      ),
                      16.verticalSpace,
                      // Text
                      AppText(
                        'No',
                        style: AppStyle.text16.copyWith(
                          color: isNativeEnglishSpeaker == false
                              ? const Color(0xFF0D121C) // content/primary
                              : const Color(0xFF7F8EA4), // Text/Tertiary
                          fontWeight: isNativeEnglishSpeaker == false ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
