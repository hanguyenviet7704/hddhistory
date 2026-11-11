part of '../../../../../roleplay.dart';

class RoleplaySpeakingAnswer extends StatelessWidget {
  final AnswerEntity recordAnswer;
  final TextStyle textStyle;

  const RoleplaySpeakingAnswer({
    super.key,
    required this.recordAnswer,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (recordAnswer.record.isNotEmpty) {
      return RoleplayAudioAnswerPlayer(
        source: recordAnswer.record,
        onPlayTap: () {
          final trackingData = RoleplayTrackingData.fromContext();
          if (trackingData != null) {
            AppService.instance.appTrackingService.trackRoleplayQuizCollapsedReplay(trackingData);
          }
        },
      );
    }

    if (recordAnswer.review.isNotEmpty) {
      return AppText(
        recordAnswer.review,
        maxLines: 8,
        overflow: TextOverflow.visible,
        style: textStyle,
      );
    }

    return const SizedBox.shrink();
  }
}
