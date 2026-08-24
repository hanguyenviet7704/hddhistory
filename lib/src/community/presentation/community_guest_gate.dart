part of '../community.dart';

/// Whether this reader may write — and if not, taking them somewhere that says
/// why.
///
/// Two different answers, handled differently on purpose:
///
/// - A **guest** is sent to the auth screen. Pushed, not `go`, matching the
///   Profile avatar and the Settings sign-in row: backing out returns them to
///   the thread they were reading instead of dumping them on Home. On the way
///   back the member status is re-read, so signing in unlocks the composer
///   without needing to leave and re-enter the tab.
/// - A **suspended member** is told the reason. There is nothing for them to do
///   on a login screen, and sending them there would read as the app losing
///   their session.
///
/// Returns true only when the caller should go ahead.
Future<bool> communityRequireAccount(
  BuildContext context,
  CommunityMemberStatusEntity status,
) async {
  if (status.canPost) return true;

  final l10n = context.l10n.community;

  if (!status.requiresLogin) {
    DMessage.showMessage(
      message: status.reason?.trim().isNotEmpty == true
          ? status.reason!
          : l10n.mutedBodyFallback,
      type: MessageType.info,
    );
    return false;
  }

  AppHaptic.select();
  await const RegisterRoute().push(context);

  // The singleton feed cubit owns the status the whole tab reads, so refreshing
  // it here is what re-opens the composer and the write affordances.
  await AppDI.injector.get<CommunityFeedCubit>().refreshMemberStatus();

  return false;
}

/// The status for screens that hold no cubit of their own (the saved list).
CommunityMemberStatusEntity get communityMemberStatus =>
    AppDI.injector.get<CommunityFeedCubit>().state.memberStatus;
