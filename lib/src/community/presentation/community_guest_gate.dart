part of '../community.dart';

/// Whether this reader may write — and if not, saying so where they are.
///
/// Both answers arrive as the notice strip at the top of the screen, not as a
/// screen change: the reader tapped a heart or a follow chip, they did not ask
/// to go anywhere, and yanking them onto an auth page loses the post they were
/// reading. The guest notice is TAPPABLE — that is the way to the sign-in
/// screen, taken only if they want it.
///
/// - A **guest** gets the invitation, and tapping it opens auth. Coming back
///   re-reads the member status, so signing in unlocks the composer and the
///   write affordances without leaving and re-entering the tab.
/// - A **suspended member** gets the moderator's reason. There is nothing for
///   them to do on a login screen, and sending them there would read as the app
///   losing their session.
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
  DMessage.showMessage(
    message: l10n.guestBody,
    type: MessageType.info,
    onTap: _openCommunityAuth,
  );

  return false;
}

/// Opens the auth screen from a notice tap.
///
/// Reads the root context rather than closing over the caller's: by the time
/// the notice is tapped the widget that showed it may be gone (the reader can
/// scroll, or leave the thread, while it is still up).
Future<void> _openCommunityAuth() async {
  final context = AppConfig.instance.context;
  if (context == null) return;

  await const RegisterRoute().push(context);

  // The singleton feed cubit owns the status the whole tab reads, so refreshing
  // it here is what re-opens the composer and the write affordances.
  await AppDI.injector.get<CommunityFeedCubit>().refreshMemberStatus();
}

/// The status for screens that hold no cubit of their own (the saved list).
CommunityMemberStatusEntity get communityMemberStatus =>
    AppDI.injector.get<CommunityFeedCubit>().state.memberStatus;
