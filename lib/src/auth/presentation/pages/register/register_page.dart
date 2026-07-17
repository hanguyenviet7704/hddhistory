part of '../../../auth.dart';

@visibleForTesting
bool shouldBootstrapRegisterGuestSession({
  required Future<bool>? bootstrapFuture,
  String accessToken = '',
}) {
  return accessToken.isEmpty && bootstrapFuture == null;
}

@visibleForTesting
AuthEvent buildGuestRegisterAuthEvent({
  required bool forceChooseCourseAfterLogin,
  required bool showPaywallAfterAuth,
}) {
  return AuthEvent.loginAnonymousGuest(
    forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
    showPaywallAfterAuth: showPaywallAfterAuth,
  );
}

enum _AuthMethod { guest, google, apple }

class RegisterPage extends StatefulWidget {
  final bool forceChooseCourseAfterLogin;
  final bool showPaywallAfterAuth;

  const RegisterPage({
    super.key,
    this.forceChooseCourseAfterLogin = false,
    this.showPaywallAfterAuth = false,
  }) : assert(
         !(forceChooseCourseAfterLogin && showPaywallAfterAuth),
         'RegisterPage cannot force course selection and show paywall after auth at the same time.',
       );

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<bool>? _bootstrapFuture;
  final ValueNotifier<bool> _isBootstrapInProgress = ValueNotifier(false);
  // Which button (if any) is mid-flight, from tap to navigation-away — drives
  // that specific button's spinner instead of a silent dead zone. Guest is
  // cleared locally once `continueWithCurrentGuestSession` resolves (it's a
  // plain awaitable method); Google/Apple dispatch a bloc EVENT (fire and
  // forget from the caller's side), so those are cleared by the
  // AuthBloc listener below reacting to `state.status` leaving `.loading`.
  final ValueNotifier<_AuthMethod?> _activeAuthMethod = ValueNotifier(null);

  bool get _showPaywallAfterAuth => widget.showPaywallAfterAuth && !widget.forceChooseCourseAfterLogin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureGuestBootstrapStarted());
    });
  }

  Future<bool> _ensureGuestBootstrapStarted() {
    final inFlight = _bootstrapFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final accessToken = context.read<UserCubit>().state.accessToken;
    if (!shouldBootstrapRegisterGuestSession(
      accessToken: accessToken,
      bootstrapFuture: _bootstrapFuture,
    )) {
      return Future.value(false);
    }

    _isBootstrapInProgress.value = true;

    final task = context
        .read<AuthBloc>()
        .bootstrapGuestSessionForRegister()
        .then((success) {
          _isBootstrapInProgress.value = false;
          return success;
        })
        .catchError((_) {
          _isBootstrapInProgress.value = false;
          return false;
        });

    _bootstrapFuture = task;
    return task;
  }

  @override
  void dispose() {
    _isBootstrapInProgress.dispose();
    _activeAuthMethod.dispose();
    super.dispose();
  }

  void _onLoginGuest() {
    unawaited(_handleGuestLogin());
  }

  Future<void> _handleGuestLogin() async {
    if (_activeAuthMethod.value != null) return;
    _activeAuthMethod.value = _AuthMethod.guest;
    try {
      final authBloc = context.read<AuthBloc>();
      await _ensureGuestBootstrapStarted();
      if (!mounted) return;
      // continueWithCurrentGuestSession already resolves internally whether
      // this is a same-session continue or a fresh anonymous login + navigate
      // (see resolveRegisterGuestContinueAction inside it) — no need to
      // duplicate that branching here, and being directly awaitable (unlike
      // dispatching a bloc event) lets this method's own try/finally track
      // the busy state for the whole span.
      await authBloc.continueWithCurrentGuestSession(
        forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
        showPaywallAfterAuth: _showPaywallAfterAuth,
      );
    } finally {
      if (mounted) _activeAuthMethod.value = null;
    }
  }

  void _onLoginGoogle() {
    unawaited(
      _dispatchAuthChoice(
        _AuthMethod.google,
        AuthEvent.loginSSOGoogle(
          forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: _showPaywallAfterAuth,
        ),
      ),
    );
  }

  void _onLoginApple() {
    unawaited(
      _dispatchAuthChoice(
        _AuthMethod.apple,
        AuthEvent.loginSSOApple(
          forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: _showPaywallAfterAuth,
        ),
      ),
    );
  }

  Future<void> _dispatchAuthChoice(_AuthMethod method, AuthEvent event) async {
    if (_activeAuthMethod.value != null) return;
    _activeAuthMethod.value = method;
    await _ensureGuestBootstrapStarted();
    if (!mounted) return;
    // `add()` can't be awaited — `_activeAuthMethod` is cleared by the
    // BlocListener below once AuthState.status leaves `.loading` (success
    // navigates away; failure stays on this page and must un-freeze it).
    context.read<AuthBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    // Google/Apple dispatch a bloc event (fire-and-forget from this page's
    // side, so there's no Future to await), unlike the guest button's direct
    // `continueWithCurrentGuestSession` call, which clears `_activeAuthMethod`
    // itself in a `finally`. This is what un-freezes the SSO buttons once the
    // attempt resolves: success navigates away (this page is gone by then
    // anyway), failure leaves the user here and must restore tappability.
    listenWhen: (previous, current) => previous.status != current.status && current.status != AuthStatus.loading,
    listener: (context, state) {
      if (_activeAuthMethod.value != null) _activeAuthMethod.value = null;
    },
    child: AuthLayout(
      body: Container(
        color: const Color(0xFFEBEAFD),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Image.asset(AppAsset.images.common.logoBanner.path, height: 60.h),
                      66.verticalSpace,
                      AppText(
                        context.l10n.auth.authHeadLine,
                        maxLines: 5,
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        style: AppStyle.textBold20.copyWith(
                          color: const Color(0xFF110751),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      126.verticalSpace,
                      ValueListenableBuilder<bool>(
                        valueListenable: _isBootstrapInProgress,
                        builder: (context, isBootstrapInProgress, _) => ValueListenableBuilder<_AuthMethod?>(
                          valueListenable: _activeAuthMethod,
                          builder: (context, activeMethod, _) => IgnorePointer(
                            // Silent during the mount-time bootstrap (no button
                            // has been tapped yet, so there's nothing to show a
                            // spinner on); once a button IS tapped, the button
                            // itself renders the spinner (see isLoading below)
                            // instead of this IgnorePointer masking a static look.
                            ignoring: isBootstrapInProgress || activeMethod != null,
                            child: Column(
                              children: [
                                if (Platform.isIOS) ...[
                                  AppleLoginButton(onPressed: _onLoginApple, isLoading: activeMethod == _AuthMethod.apple),
                                  16.verticalSpace,
                                ],
                                GoogleLoginButton(onPressed: _onLoginGoogle, isLoading: activeMethod == _AuthMethod.google),
                                16.verticalSpace,
                                GuestLoginButton(onPressed: _onLoginGuest, isLoading: activeMethod == _AuthMethod.guest),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 20.h, left: 30.w, right: 30.w),
                child: const _RegisterLegalLinks(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RegisterLegalLinks extends StatelessWidget {
  const _RegisterLegalLinks();

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppStyle.text12.copyWith(
      color: const Color(0xFF110751).op(0.5),
      height: 1.75,
    );
    final linkStyle = baseStyle.copyWith(decoration: TextDecoration.underline);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.l10n.auth.authLegalNoticePrefix, style: baseStyle, textAlign: TextAlign.center),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InlineLegalLink(
              label: context.l10n.auth.privacyPolicy,
              url: LegalUrl.privacyPolicy,
              style: linkStyle,
            ),
            Text(', ', style: baseStyle),
            _InlineLegalLink(
              label: context.l10n.auth.termsAndConditions,
              url: LegalUrl.termsAndConditions,
              style: linkStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineLegalLink extends StatelessWidget {
  final String label;
  final String url;
  final TextStyle style;

  const _InlineLegalLink({required this.label, required this.url, required this.style});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: url.launchURL,
    child: Text(label, style: style),
  );
}
