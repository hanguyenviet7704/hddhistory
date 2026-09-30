part of '../../profile.dart';

// ---------------------------------------------------------------------------
// Shared design tokens for the redesigned Profile + Achievements screens
// (design: flat lavender background, soft white cards — mirrors the same
// treatment already shipped on Home, see home_page.dart's _homeCardShadow /
// _homeBackground). Declared once here; visible to every `part of
// profile.dart` file in this library (e.g. achievements_full_page.dart).
// ---------------------------------------------------------------------------

/// Flat lavender page background behind the white cards (design #F4F4FB).
const Color _profileBackground = Color(0xFFFBF9F4);

/// Muted secondary text/icon color used throughout this design (design
/// #9AA4B2) — close to but distinct from the shared textTertiary token, so
/// it's kept as a scoped one-off rather than widened into AppCustomColor.
const Color _profileMutedTextColor = Color(0xFF9AA4B2);

/// Progress-bar track color used by both the Learning Progress rows and the
/// Achievements badge grid (design #E7E9F2).
const Color _profileProgressTrackColor = Color(0xFFE7E9F2);

/// Heading/title helper. Uses the app's default font (Mulish, `AppFont.mulish`)
/// so Profile matches the rest of the app (e.g. the Habit screens) — the earlier
/// Poppins display font was dropped for a single consistent typeface.
TextStyle _poppins(
  double size,
  FontWeight weight, {
  Color color = AppCustomColor.textPrimary,
  double? height,
}) =>
    TextStyle(fontFamily: AppFont.mulish, fontSize: size.sp, fontWeight: weight, color: color, height: height);


// ---------------------------------------------------------------------------
// What is left of the old Profile screen.
//
// Profile stopped being a screen of its own on 2026-09-04: its progress blocks
// moved to Home and everything else moved into Settings, which the Home header
// gear now opens directly. These two cards are that "everything else", kept
// here because the file also owns the design tokens the rest of this library
// reads (achievements_full_page.dart, profile_info_page.dart).
// ---------------------------------------------------------------------------

/// The identity CLUSTER, in a white card under the title bar (design
/// `6 · Profile`: avatar 72 · name 21 · email · an "Edit profile" pill).
/// The pill replaces the old pencil-beside-the-name as the sole way into the
/// edit screen — guests get it too (a guest account has a real id on the
/// server, so rename/avatar save the same way; only account DELETION stays
/// login-gated, which the edit screen enforces itself).
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Only a bottom gap (design `margin:2px 0 16px`): the screen that hosts
    // this pays the horizontal inset for every section on it.
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: BlocSelector<ProfileCubit, ProfileState, UserEntity>(
        selector: (state) => state.user,
        builder: (context, user) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0F3C3114),
                  blurRadius: 24.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Guests can tap their avatar to open the login screen.
                if (user.anonymous)
                  Semantics(
                    button: true,
                    label: context.l10n.auth.authLogIn,
                    child: GestureDetector(
                      key: const Key('profile-avatar-login-button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptic.select();
                        const RegisterRoute().push(context);
                      },
                      child: _ProfileAvatar(user: user, dimension: 64, initialFontSize: 26),
                    ),
                  )
                else
                  _ProfileAvatar(user: user, dimension: 64, initialFontSize: 26),
                14.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _resolveName(user, context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _poppins(19, FontWeight.w700, color: AppCustomColor.textPrimary),
                      ),
                      2.verticalSpace,
                      AppText(
                        _resolveEmail(user),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.text13.copyWith(
                          color: _profileMutedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      8.verticalSpace,
                      const _ProfileEditButton(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _resolveName(UserEntity user, BuildContext context) {
    final trimmed = user.name.trim();
    return trimmed.isNotEmpty ? trimmed : context.l10n.setting.settingGuestName;
  }

  String _resolveEmail(UserEntity user) => user.email.trim();
}


class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton();

  @override
  Widget build(BuildContext context) {
    // Design pill: #E8E7FA, 22 tall, pencil + label 10.5/700 — a labelled
    // affordance where the bare pencil disc used to be.
    return Semantics(
      button: true,
      label: context.l10n.setting.settingEditProfileButton,
      child: GestureDetector(
        key: const Key('profile-edit-button'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          ProfileInfoRoute().go(context);
        },
        child: Container(
          height: 22.h,
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          decoration: BoxDecoration(
            color: AppCustomColor.profileEditPencilBg,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 11.w, color: AppCustomColor.brandPrimary),
              4.horizontalSpace,
              AppText(
                context.l10n.setting.settingEditProfileButton,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppCustomColor.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    this.dimension = 52,
    this.initialFontSize = 20,
  });

  final UserEntity user;

  /// Logical size before scaling — the identity header uses the default;
  /// the edit screen renders the same widget larger.
  final double dimension;
  final double initialFontSize;

  @override
  Widget build(BuildContext context) {
    final double size = dimension.w;

    if (user.avatar.trim().isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: CacheNetworkGraphic(
            url: user.avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final String initial = _buildInitial(context);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppCustomColor.brandPrimary700,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: _poppins(initialFontSize, FontWeight.w700, color: AppCustomColor.backgroundWhite),
      ),
    );
  }

  String _buildInitial(BuildContext context) {
    String ref = user.name.trim();
    if (ref.isEmpty) ref = user.email.trim();
    if (ref.isEmpty) ref = context.l10n.setting.settingGuestName;
    return String.fromCharCode(ref.runes.first).toUpperCase();
  }
}


class ProfilePremiumBanner extends StatelessWidget {
  const ProfilePremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) => state.user.isPremium,
      builder: (context, isPremium) {
        // A paying reader is never sold to. The gap goes with the card —
        // the section below pays its own top margin.
        if (isPremium) return const SizedBox.shrink();

        final text = context.l10n.setting;

        return Padding(
          padding: EdgeInsets.only(bottom: 28.h),
          child: Semantics(
            button: true,
            label: text.settingPremiumTitle,
            child: GestureDetector(
              key: const Key('profile-premium-banner'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppHaptic.select();
                AppService.instance.appTrackingService.trackProfileUpgradeClick(source: 'profile_banner');
                AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.profile);
                const PaywallRoute().push(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            text.settingPremiumTitle,
                            style: _poppins(15, FontWeight.w700, color: AppCustomColor.backgroundWhite),
                          ),
                          2.verticalSpace,
                          AppText(
                            text.settingPremiumSubtitle,
                            style: AppStyle.text12.copyWith(
                              color: const Color(0xFFF7EDD3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    14.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundWhite,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: AppText(
                        text.settingPremiumUpgradeCta,
                        style: AppStyle.textBold12.copyWith(
                          fontSize: 13.sp,
                          color: AppCustomColor.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
