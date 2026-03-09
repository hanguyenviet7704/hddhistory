part of '../../../auth.dart';

class RegisterPage extends StatelessWidget {
  final bool forceChooseCourseAfterLogin;

  const RegisterPage({
    super.key,
    this.forceChooseCourseAfterLogin = false,
  });

  void _onLoginGuest(BuildContext context) {
    if (forceChooseCourseAfterLogin) {
      context.read<AuthBloc>().add(
        const AuthEvent.loginAnonymousGuest(forceChooseCourseAfterLogin: true),
      );
      return;
    }

    final RoadmapEntity roadmap = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap;
    if (roadmap.id.isEmpty) {
      CourseRoute(selectedTabIndex: 0).go(context);
      return;
    }

    HomeRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(0);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      body: Container(
        color: const Color(0xFFEBEAFD), // Background color from Figma
        child: SafeArea(
          child: Column(
            children: [
              // Top section with "Already member? Log in" text
              if (kDebugMode)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppText(
                        context.text.auth.authAlreadyMember,
                        style: AppStyle.text14.copyWith(
                          color: const Color(0xFF110751),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      4.horizontalSpace,
                      GestureDetector(
                        onTap: () {
                          // Navigate to login page
                          // DNavigator.goNamed(RouteNamed.login);
                        },
                        child: AppText(
                          context.text.auth.authLogIn,
                          style: AppStyle.text14.copyWith(
                            color: const Color(0xFF110751),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Image.asset(
                        AppAsset.images.common.logoBanner.path,
                        height: 60.h,
                      ),
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

                      // Social login buttons
                      Column(
                        children: [
                          // Apple button
                          if (Platform.isIOS) ...[
                            AppleLoginButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(
                                  AuthEvent.loginSSOApple(
                                    forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
                                  ),
                                );
                              },
                            ),
                            16.verticalSpace,
                          ],

                          // Google button
                          GoogleLoginButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                AuthEvent.loginSSOGoogle(
                                  forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
                                ),
                              );
                            },
                          ),

                          16.verticalSpace,

                          // Guest button
                          GuestLoginButton(
                            onPressed: () => _onLoginGuest(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section with privacy policy and terms
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
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: url.launchURL,
      child: Text(label, style: style),
    );
  }
}
