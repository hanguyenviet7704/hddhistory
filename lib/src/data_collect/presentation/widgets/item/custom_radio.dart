part of '../../../data_collect.dart';

class CustomRadio extends StatelessWidget {
  final bool isSelected;

  const CustomRadio({
    super.key,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.w,
      padding: EdgeInsets.all(2.w),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAE7F09) : Colors.white, // button/primary/default or white
          border: Border.all(
            color: isSelected ? const Color(0xFFAE7F09) : const Color(0xFFE3E8EF), // button/primary/default or Border/Default
            width: 2.w,
          ),
          shape: BoxShape.circle,
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 8.229.w,
                  height: 8.229.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
