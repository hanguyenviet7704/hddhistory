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
}) {
  return AuthEvent.loginAnonymousGuest(
    forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
  );
}

class RegisterPage extends StatefulWidget {
  final bool forceChooseCourseAfterLogin;

  const RegisterPage({
    super.key,
    this.forceChooseCourseAfterLogin = false,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<bool>? _bootstrapFuture;
  final ValueNotifier<bool> _isBootstrapInProgress = ValueNotifier(false);

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
    super.dispose();
  }

  void _onLoginGuest() {
    unawaited(_handleGuestLogin());
  }

  Future<void> _handleGuestLogin() async {
    final authBloc = context.read<AuthBloc>();
    await _ensureGuestBootstrapStarted();
    if (!mounted) return;

    switch (resolveRegisterGuestContinueAction(
      hasBootstrappedGuestSession: authBloc.hasActiveAnonymousSession,
    )) {
      case RegisterGuestContinueAction.continueCurrentSession:
        await authBloc.continueWithCurrentGuestSession(
          forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
        );
        return;
      case RegisterGuestContinueAction.loginAnonymousAndNavigate:
        authBloc.add(
          buildGuestRegisterAuthEvent(
            forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
          ),
        );
        return;
    }
  }

  void _onLoginGoogle() {
    unawaited(
      _dispatchAuthChoice(
        AuthEvent.loginSSOGoogle(
          forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
        ),
      ),
    );
  }

  void _onLoginApple() {
    unawaited(
      _dispatchAuthChoice(
        AuthEvent.loginSSOApple(
          forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
        ),
      ),
    );
  }

  Future<void> _dispatchAuthChoice(AuthEvent event) async {
    await _ensureGuestBootstrapStarted();
    if (!mounted) return;
    context.read<AuthBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    body: Container(
      color: const Color(0xFFEBEAFD),
      child: SafeArea(
        child: Column(
          children: [
            if (kDebugMode) const _RegisterTopLoginHint(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    Image.asset(AppAsset.images.common.logoBanner.path, height: 60.h),
                    66.verticalSpace,
                    AppText(
                      context.text.auth.authHeadLine,
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
                      builder: (context, isBootstrapInProgress, child) => IgnorePointer(
                        ignoring: isBootstrapInProgress,
                        child: child,
                      ),
                      child: Column(
                        children: [
                          if (Platform.isIOS) ...[
                            AppleLoginButton(onPressed: _onLoginApple),
                            16.verticalSpace,
                          ],
                          GoogleLoginButton(onPressed: _onLoginGoogle),
                          16.verticalSpace,
                          GuestLoginButton(onPressed: _onLoginGuest),
                        ],
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
  );
}

class _RegisterTopLoginHint extends StatelessWidget {
  const _RegisterTopLoginHint();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppText(
          context.text.auth.authAlreadyMember,
          style: AppStyle.text14.copyWith(color: const Color(0xFF110751)),
        ),
        4.horizontalSpace,
        AppText(
          context.text.auth.authLogIn,
          style: AppStyle.text14.copyWith(
            color: const Color(0xFF110751),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
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
        Text(context.text.auth.authLegalNoticePrefix, style: baseStyle, textAlign: TextAlign.center),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InlineLegalLink(
              label: context.text.auth.privacyPolicy,
              url: LegalUrl.privacyPolicy,
              style: linkStyle,
            ),
            Text(', ', style: baseStyle),
            _InlineLegalLink(
              label: context.text.auth.termsAndConditions,
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
