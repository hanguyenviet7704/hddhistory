part of '../../../monetization.dart';

/// One benefit line on the paywall.
///
/// Every row carries the SAME check mark rather than its own illustration. The
/// icons this used to render (`pw_lessons`, `pw_practice`, …) were 28px colour
/// drawings, one per row — at three rows they read as three unrelated pictures
/// and pulled the eye away from the words, which are the part that sells. A
/// repeated check turns the list back into a list: the reader scans the claims,
/// not the artwork.
///
/// The consequence to know about: `benefit.icon` from the paywall config is no
/// longer rendered here. Setting an icon in the admin panel changes nothing on
/// this screen.
class _PaywallBenefitRow extends StatelessWidget {
  final String text;

  const _PaywallBenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22.w,
          height: 22.w,
          child: Center(
            child: Icon(
              Icons.check_rounded,
              size: 20.w,
              color: AppCustomColor.textBrand,
            ),
          ),
        ),
        14.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textBrand,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
