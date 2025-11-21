part of '../../../auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
                        context.text.authAlreadyMember,
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
                          context.text.authLogIn,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and tagline
                      Column(
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              AppAsset.images.common.mainIcon.path,
                              width: 80.w,
                            ),
                          ),
                          24.verticalSpace,
                          AppText(
                            context.text.authHeadLine,
                            maxLines: 5,
                            style: AppStyle.text24.copyWith(
                              color: const Color(0xFF110751),
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      32.verticalSpace,

                      // Social login buttons
                      Column(
                        children: [
                          // Apple button
                          if (Platform.isIOS) ...[
                            AppleLoginButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(const AuthEvent.loginSSOApple());
                              },
                            ),
                            16.verticalSpace,
                          ],

                          // Google button
                          GoogleLoginButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(const AuthEvent.loginSSOGoogle());
                            },
                          ),

                          16.verticalSpace,

                          // Guest button
                          GuestLoginButton(
                            onPressed: () {
                              // Continue as guest
                              // Navigate to home
                              // DNavigator.goNamed(RouteNamed.home);
                              AppDI.injector.get<LessonCubit>().loadAllLearningItems(isInit: true);
                              CourseRoute().go(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section with privacy policy and terms
              Padding(
                padding: EdgeInsets.only(bottom: 20.h, left: 50.w, right: 50.w),
                child: AppText(
                  context.text.authLegalNotice,
                  maxLines: 5,
                  style: AppStyle.text12.copyWith(
                    color: const Color(0xFF110751).op(0.5),
                    height: 1.75,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
