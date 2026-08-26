part of '../../../common.dart';

@lazySingleton
class DeeplinkCubit extends Cubit<DeeplinkState> {
  final IDeepLinkService _deepLinkService;
  DeeplinkCubit(this._deepLinkService) : super(DeeplinkState.initial()) {
    init();
  }

  StreamSubscription<Uri?>? _homeWidgetClickSubscription;
  StreamSubscription<NotificationInteraction>? _notificationInteractionSubscription;
  StreamSubscription<PageState>? _onboardingExitSubscription;
  String _serviceRoutePath = '';
  String _pendingUriKey = '';
  String _lastHandledInitialUriKey = '';
  Map<String, String> _serviceRouteQuery = {};
  DeeplinkTarget? _pendingTarget;

  void init() {
    _deepLinkService.uriStream.listen(
      (uri) => navigationFromService(uri),
      onDone: () {
        // _deepLinkService.uriStream.drain();
      },
      onError: (error, stackTrace) => LogDev.one('navigationFromService error: $error, stackTrace: $stackTrace'),
    );
    _homeWidgetClickSubscription = home_widget_plugin.HomeWidget.widgetClicked.listen(
      (uri) {
        if (uri == null) return;
        navigationFromService(uri);
      },
      onError: (error, stackTrace) => LogDev.one('homeWidgetClicked error: $error, stackTrace: $stackTrace'),
    );
    // Live Activity return-nudge taps arrive as notification interactions, not
    // deeplink URIs, so bridge them here — mirrors the home-widget click
    // subscription above. Only the one nudge id is acted on; everything else is
    // ignored inside the handler.
    _notificationInteractionSubscription = NotificationService.interactionStream.listen(
      _handleNotificationInteraction,
      onError: (error, stackTrace) => LogDev.one('notificationInteraction error: $error, stackTrace: $stackTrace'),
    );
  }

  void resetServiceRouteData() {
    _serviceRoutePath = '';
    _pendingUriKey = '';
    _serviceRouteQuery = {};
    _pendingTarget = null;
  }

  bool setIsPassSplashScreen(bool isPassSplashScreen) {
    if (state.isPassSplashScreen != isPassSplashScreen) {
      emit(state.copyWith(isPassSplashScreen: isPassSplashScreen));
    }

    if (!isPassSplashScreen) return false;
    return handleRoute();
  }

  bool navigationFromService(Uri uri) {
    try {
      _resolveServiceLink(uri);
      return handleRoute();
    } catch (error, stackTrace) {
      LogDev.error('navigationFromService failed: $error\r\n$stackTrace');
      resetServiceRouteData();
      return false;
    }
  }

  Future<bool> initialLink() async {
    try {
      Uri? uri = await _deepLinkService.getInitialLink();
      if (uri != null && _lastHandledInitialUriKey == uri.toString()) {
        LogDev.info('Skipping duplicate initial deeplink: $uri');
        return false;
      }
      if (uri != null && navigationFromService(uri)) return true;

      // The home_widget plugin requires the iOS app-group id to be set before
      // any other call in the session; otherwise this throws
      // PlatformException(-7, "AppGroupId not set") on every cold start,
      // breaking launch-from-widget deeplinks (the widget bridge only sets it
      // when a widget sync runs, which is too late for this path).
      await home_widget_plugin.HomeWidget.setAppGroupId(HomeWidgetAppGroups.current());
      uri = await home_widget_plugin.HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri == null) return false;
      if (_lastHandledInitialUriKey == uri.toString()) {
        LogDev.info('Skipping duplicate initial home widget deeplink: $uri');
        return false;
      }
      return navigationFromService(uri);
    } catch (error, stackTrace) {
      LogDev.error('initialLink failed: $error\r\n$stackTrace');
      resetServiceRouteData();
      return false;
    }
  }

  bool handleRoute() {
    if (!state.isPassSplashScreen || _serviceRoutePath.isEmpty) return false;
    _handleServiceRouteParam();
    final isHandled = _handleLiveActivityRoute() || _handleShellRoute() || _handleDestination();
    if (isHandled) {
      _lastHandledInitialUriKey = _pendingUriKey;
    }
    if (!isHandled) {
      LogDev.warning('Ignoring unsupported deeplink route: $_serviceRoutePath');
    }
    // Chưa qua onboarding thì GIỮ link lại và chạy lại khi vào được app. Đây là
    // lần duy nhất không reset: mọi lối ra khác đều đã dùng xong hoặc đã bỏ link.
    if (!isHandled && _pendingTarget != null && _shouldDeferForOnboarding()) {
      _ensureOnboardingWatch();
      return false;
    }
    resetServiceRouteData();
    return isHandled;
  }

  bool _handleShellRoute() {
    final target = HomeWidgetDeeplinkTarget.tryParse(Uri(path: _serviceRoutePath, queryParameters: _serviceRouteQuery));
    if (target == null) return false;
    return _handleHomeWidgetRoute(target);
  }

  /// Điều hướng theo bảng đích. Chạy SAU live-activity và home-widget: hai
  /// handler đó khoá theo `source=` và mang analytics riêng của chúng.
  bool _handleDestination() {
    final target = _pendingTarget;
    if (target == null) return false;

    // Deeplink không được vượt lên trước onboarding. Trả false để splash tự
    // quyết đi đâu — nó dùng đúng giá trị này để biết deeplink có chiếm quyền
    // điều hướng hay không (xem splash_page.dart `_initScreen`).
    if (_shouldDeferForOnboarding()) {
      LogDev.info('Deferring deeplink until onboarding finishes: ${target.rawKey}');
      _trackDeeplinkOpen(target, resolved: false, reason: 'pre_auth_deferred');
      return false;
    }

    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring deeplink because navigator context is unavailable');
      _trackDeeplinkOpen(target, resolved: false, reason: 'missing_context');
      return false;
    }

    final destination = target.destination;
    if (destination == null) {
      // Bản app cũ nhận một khoá mới. Về Home thì sai ít hơn là treo tại chỗ
      // người dùng đang đứng — đó là hành vi cũ và không ai nhận ra nó hỏng.
      LogDev.warning('Unknown deeplink destination: ${target.rawKey}');
      _trackDeeplinkOpen(target, resolved: false, reason: 'unknown_destination');
      HomeRoute().go(navContext);
      return true;
    }

    final isHandled = _navigateToDestination(navContext, destination, target);
    _trackDeeplinkOpen(target, resolved: isHandled, reason: isHandled ? '' : 'navigation_failed');
    return isHandled;
  }

  /// True khi người dùng lẽ ra sẽ bị đưa vào auth/onboarding chứ không vào app.
  ///
  /// KHÔNG kiểm theo tên route: splash gọi `initialLink()` trong lúc còn đứng
  /// TRÊN splash, nên một guard theo tên route sẽ chặn luôn mọi deeplink
  /// cold-start — kể cả những cái đang chạy tốt hôm nay. Dùng lại đúng vị từ mà
  /// splash dùng để quyết định vào Home hay vào onboarding.
  ///
  /// Lưu ý tên field bị đặt ngược: `isUserPassOnboarding == true` nghĩa là người
  /// này CÒN PHẢI onboard (mặc định `true` cho máy vừa cài).
  bool _shouldDeferForOnboarding() {
    try {
      final userState = AppDI.injector.get<UserCubit>().state;
      return AppGlobalValue.accessToken.isEmpty || userState.isUserPassOnboarding;
    } catch (error) {
      // Không đọc được trạng thái user thì coi như chưa an toàn để điều hướng.
      LogDev.warning('Could not read onboarding state for deeplink: $error');
      return true;
    }
  }

  /// Lắng `PageCubit` để chạy lại link đang treo khi người dùng đã thực sự vào
  /// trong app.
  ///
  /// Lắng PAGE chứ không lắng USER là có chủ đích. `UserCubit` emit ngay khoảnh
  /// khắc onboarding được đánh dấu xong — lúc đó người dùng vẫn còn đứng trên
  /// màn onboarding và chính nó sắp `.go()` sang Home. Replay tại đó là đua với
  /// cú `.go()` đó, và `.go()` thắng: paywall vừa `.push()` bị xoá khỏi stack,
  /// link im lặng biến mất. `PageCubit` emit khi màn đích đã claim tên của nó,
  /// tức là điều hướng của onboarding đã xong.
  ///
  /// Đăng ký LÚC CẦN chứ không trong `init()`: `DeeplinkCubit` được dựng rất
  /// sớm và không có link treo thì cũng chẳng có gì để lắng.
  void _ensureOnboardingWatch() {
    if (_onboardingExitSubscription != null) return;
    try {
      _onboardingExitSubscription = AppDI.injector.get<PageCubit>().stream.listen(
        (pageState) {
          if (_pendingTarget == null) return;
          // Cả hai điều kiện: hết lý do hoãn, VÀ app đã rời vùng pre-auth.
          if (_shouldDeferForOnboarding()) return;
          if (preAuthRouteNames.contains(pageState.currentRouteName)) return;

          unawaited(_onboardingExitSubscription?.cancel());
          _onboardingExitSubscription = null;
          LogDev.info('Replaying deferred deeplink: ${_pendingTarget?.rawKey}');
          handleRoute();
        },
        onError: (error, stackTrace) => LogDev.one('onboardingExit error: $error, stackTrace: $stackTrace'),
      );
    } catch (error) {
      LogDev.warning('Could not watch onboarding exit for deferred deeplink: $error');
    }
  }

  /// Bảng đích: khoá công khai → màn trong app.
  bool _navigateToDestination(
    BuildContext navContext,
    DeeplinkDestination destination,
    DeeplinkTarget target,
  ) {
    switch (destination) {
      case DeeplinkDestination.home:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        HomeRoute().go(navContext);
        return true;

      // `meup://paywall` — what admin enters as a banner/popup linkUrl to send
      // the tap to the paywall. Pushed over wherever the reader is (the link is
      // an offer, not a relocation), with the generic entry point: which
      // campaign sent them is the banner's own tracking's business.
      //
      // `?variant=full` / `?variant=compact` lets the LINK name the surface
      // outright, overriding the admin entry-point table — a campaign banner
      // and its landing look are then one decision made in one place. No (or an
      // unrecognised) variant falls back to the table, exactly like the plain
      // link, so an older admin entry keeps meaning what it meant.
      case DeeplinkDestination.paywall:
        final iapCubit = AppDI.injector.get<IapCubit>();
        iapCubit.setPaywallEntryPoint(PaywallEntryPoint.other);
        switch (target.params['variant']?.trim().toLowerCase()) {
          case 'full':
            iapCubit.forcePaywallVariant(PaywallProductVariant.full);
          case 'compact':
            iapCubit.forcePaywallVariant(PaywallProductVariant.compact);
        }
        unawaited(const PaywallRoute().push(navContext));
        return true;

      // Đúng chuỗi mà một cú bấm tab "Khám phá" chạy (xem
      // PageCubit.handleShellRouteNavigation case 3): mở Explore đã cuộn tới
      // course đang học, không reset về đầu danh sách.
      case DeeplinkDestination.explore:
        final selectedSkillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
        AppDI.injector.get<CourseCubit>()
          ..setAllCourseSource(deeplinkRoadmapSource)
          ..jumpToSkillset(selectedSkillsetIndex);
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.course);
        CourseRoute().go(navContext);
        return true;

      case DeeplinkDestination.habit:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
        HabitRoute().go(navContext);
        return true;

      case DeeplinkDestination.profile:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ProfileRoute().go(navContext);
        return true;

      case DeeplinkDestination.library:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.library);
        LibraryRoute().go(navContext);
        return true;

      // `meup://community` — the forum tab.
      case DeeplinkDestination.community:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.community);
        const CommunityRoute().go(navContext);
        return true;

      // `meup://community-post?postId=...` — where a community push lands.
      //
      // The tab is opened first and the thread pushed on top of it, so backing
      // out of the notification leaves the reader in the community rather than
      // wherever they happened to be when the push arrived.
      case DeeplinkDestination.communityPost:
        final communityPostId = target.params['postId']?.trim() ?? '';
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.community);
        const CommunityRoute().go(navContext);
        if (communityPostId.isEmpty) {
          _trackDeeplinkOpen(target, resolved: false, reason: 'missing_param');
          return true;
        }
        unawaited(CommunityPostRoute(postId: communityPostId).push(navContext));
        return true;

      // `courseId` là tuỳ chọn: không truyền thì mở roadmap của course đang
      // chọn. Course không chọn được (đã unpublish sau khi link phát ra) thì về
      // Home — giống hệt nhánh `course_not_found` của luồng home widget.
      case DeeplinkDestination.courseRoadmap:
        final courseId = target.params['courseId']?.trim() ?? '';
        if (_openCourseRoadmap(navContext, courseId, deeplinkRoadmapSource)) return true;
        HomeRoute().go(navContext);
        _trackDeeplinkOpen(target, resolved: false, reason: 'entity_not_found');
        return true;

      // Không có đường mở thẳng một lesson: `LessonRoute` không nhận id, nội
      // dung bài do CourseLessonCubit giữ và roadmap là màn nạp dữ liệu course.
      // Nên đi đúng cơ chế mà Live Activity đã dùng: giao keypoint cho roadmap
      // và để nó mở bài khi đã resolve được id.
      //
      // Bài bị khoá/chưa mua thì roadmap tự xử theo gate sẵn có. Deeplink là
      // đường đi, không phải chìa khoá.
      case DeeplinkDestination.lesson:
        final lessonCourseId = target.params['courseId']?.trim() ?? '';
        if (lessonCourseId.isEmpty) {
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'missing_param');
          return true;
        }

        final keypointId = target.params['keypointId']?.trim() ?? '';
        final roadmapCubit = AppDI.injector.get<CourseRoadmapCubit>();
        if (keypointId.isNotEmpty) roadmapCubit.setPendingResumeKeypointId(keypointId);

        if (!_openCourseRoadmap(navContext, lessonCourseId, deeplinkRoadmapSource)) {
          // Không có roadmap để đứng thì cũng không có ai tiêu thụ yêu cầu này.
          roadmapCubit.clearPendingResumeKeypointId();
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'entity_not_found');
        }
        return true;

      case DeeplinkDestination.skillsetCourses:
        final skillsetId = target.params['skillsetId']?.trim() ?? '';
        if (skillsetId.isEmpty) {
          HomeRoute().go(navContext);
          _trackDeeplinkOpen(target, resolved: false, reason: 'missing_param');
          return true;
        }
        // Claim branch 1 trước, rồi push trang con: cú push trong branch có
        // didPush nên trang con tự nhận tên của mình qua route observer.
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
        SkillsetCoursesRoute(skillsetId: skillsetId).go(navContext);
        return true;

      // Tám đích dưới đây lồng trong một tab. Mỗi cái claim tên của BRANCH nó
      // nằm trong trước khi `.go()`; trang con tự nhận tên riêng khi push.
      case DeeplinkDestination.dailyWarmUp:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        DailyWarmUpRoute().go(navContext);
        return true;

      case DeeplinkDestination.learningStreak:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        HomeLearningStreakRoute().go(navContext);
        return true;

      case DeeplinkDestination.dailyCheckIn:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
        DailyCheckInRoute().go(navContext);
        return true;

      // Claim tên CỦA CHÍNH NÓ, không phải tên branch: `myLessons` đã chuyển từ
      // branch Profile sang branch Library (xem routes_shell.dart) và
      // `_tabIndexForRouteName` map thẳng `myLessons` → branch 5. Claim
      // `RouteNamed.profile` ở đây sẽ sáng sai tab.
      case DeeplinkDestination.myLessons:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.myLessons);
        MyLessonsRoute().go(navContext);
        return true;

      // ImportLessonRoute khai trong routes_shell_setting_data.dart nhưng LẮP
      // dưới branch Explore (xem routes_shell.dart) — nên claim tên Explore,
      // không phải Profile.
      case DeeplinkDestination.importLesson:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.course);
        ImportLessonRoute().go(navContext);
        return true;

      case DeeplinkDestination.notificationSetting:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        NotificationRoute().go(navContext);
        return true;

      case DeeplinkDestination.changeLanguage:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ChangeLanguageRoute().go(navContext);
        return true;

      case DeeplinkDestination.manageSubscription:
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.profile);
        ManageSubscriptionRoute().go(navContext);
        return true;

      // Không có `default:` là có chủ đích: thêm một khoá vào
      // DeeplinkDestination mà quên nối ở đây sẽ thành lỗi biên dịch ngay, chứ
      // không âm thầm trả false rồi sinh ra một link chết.
    }
  }

  void _trackDeeplinkOpen(DeeplinkTarget target, {required bool resolved, String reason = ''}) {
    unawaited(
      AppService.instance.appTrackingService.trackEvent(
        TrackingKey.deeplinkOpen,
        parameters: {
          ...target.trackingParams,
          'resolved': resolved,
          if (reason.isNotEmpty) 'reason': reason,
        },
      ).catchError((_) {}),
    );
  }

  bool _handleHomeWidgetRoute(HomeWidgetDeeplinkTarget target) {
    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring home widget deeplink because navigator context is unavailable');
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkFailure, reason: 'missing_context');
      return false;
    }

    _trackHomeWidgetRoute(target, TrackingKey.homeWidgetTap);

    if (target.routePath == RoutePath.home) {
      HomeRoute().go(navContext);
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkSuccess, resolvedRoute: RoutePath.home);
      return true;
    }

    if (target.routePath != RoutePath.courseRoadmap) return false;

    if (!_openCourseRoadmap(navContext, target.courseId, HomeWidgetDeeplinkTarget.sourceValue)) {
      HomeRoute().go(navContext);
      _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkFailure, reason: 'course_not_found', resolvedRoute: RoutePath.home);
      return true;
    }
    _trackHomeWidgetRoute(target, TrackingKey.homeWidgetDeeplinkSuccess, resolvedRoute: RoutePath.courseRoadmap);
    return true;
  }

  /// Navigates to the roadmap for [courseId], selecting it in HomeCubit first
  /// (the SAME sequence the home_widget→course deeplink uses). [source] tags the
  /// roadmap for back-nav/analytics. Returns false only when a non-empty course
  /// can't be selected, so callers can fall back to Home.
  bool _openCourseRoadmap(BuildContext navContext, String? courseId, String source) {
    if (courseId?.isNotEmpty == true) {
      final isSelected = AppDI.injector.get<HomeCubit>().trySelectCourseFromCourseId(courseId!);
      if (!isSelected) return false;
    }
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(source);
    // Not just setCurrentIndex(1) — see course_card.dart's identical fix.
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    CourseRoadmapRoute().go(navContext);
    return true;
  }

  /// The iOS Live Activity lock-screen card opens
  /// `meup://course-roadmap?courseId=…&source=live_activity`. That source is NOT
  /// a home-widget deeplink (it carries no widgetType), so
  /// [HomeWidgetDeeplinkTarget.tryParse] rejects it — before this branch the tap
  /// was logged as an unsupported route and the resume silently no-op'd. Here we
  /// navigate to the roadmap AND fire `live_resume_tap`.
  bool _handleLiveActivityRoute() {
    if (_serviceRoutePath != RoutePath.courseRoadmap) return false;
    if (_serviceRouteQuery[LiveActivityDeeplink.sourceQueryKey] != LiveActivityDeeplink.sourceValue) return false;

    final courseId = _serviceRouteQuery[LiveActivityDeeplink.courseIdQueryKey]?.trim() ?? '';
    final keypointId = _serviceRouteQuery[LiveActivityDeeplink.keypointIdQueryKey]?.trim() ?? '';
    if (!openCourseRoadmapFromLiveActivity(courseId, keypointId: keypointId)) return false;

    unawaited(
      AppService.instance.appTrackingService
          .trackEvent(TrackingKey.liveResumeTap, parameters: {'course_id': courseId, 'course_name': _resolveLiveActivityCourseName(courseId)})
          .catchError((_) {}),
    );
    return true;
  }

  /// Resumes the course roadmap for [courseId] the same way the Live Activity
  /// card does — reuses [_openCourseRoadmap] (the home_widget→course path) and
  /// falls back to Home when the course can't be selected. Public so the
  /// return-nudge interaction subscriber drives the identical resume.
  bool openCourseRoadmapFromLiveActivity(String courseId, {String keypointId = ''}) {
    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring live activity resume because navigator context is unavailable');
      return false;
    }

    // Tapping the card while the lesson it belongs to is still on screen must
    // leave navigation alone. The tap only brings a backgrounded app forward,
    // which already lands back on the lesson — `.go()`-ing to the roadmap here
    // would throw away the very lesson the user asked to return to. Counted as
    // handled so the tap still tracks and isn't logged as an unsupported route.
    //
    // A cold start still resolves to the roadmap: the card carries only
    // `courseId` (see [LiveActivityDeeplink.resumeUri]), so once the process is
    // gone nothing identifies which lesson to reopen.
    if (_isLessonFlowOnScreen(navContext)) {
      LogDev.info('Live activity resume: lesson already on screen, keeping it');
      return true;
    }

    // Cold start (or a tap from anywhere else in the app): hand the keypoint to
    // the roadmap, which is the screen that loads course data, and let it open
    // the lesson once it can resolve the id. Routing straight to the lesson from
    // here would race that fetch with nothing to fall back on.
    if (keypointId.isNotEmpty) {
      AppDI.injector.get<CourseRoadmapCubit>().setPendingResumeKeypointId(keypointId);
    }

    if (!_openCourseRoadmap(navContext, courseId, LiveActivityDeeplink.sourceValue)) {
      // No roadmap to land on, so nothing can consume the request either.
      AppDI.injector.get<CourseRoadmapCubit>().clearPendingResumeKeypointId();
      HomeRoute().go(navContext);
    }
    return true;
  }

  /// Routes a tap on one of the server's scheduled notifications, using the
  /// `deeplink` value its data payload carries. Returns false when the payload is
  /// not one of ours, so the caller can fall through to the other handlers.
  ///
  /// The server sends a symbolic destination (`home` / `resume_lesson` /
  /// `habit_tracker` / `new_course`) rather than a path, so renaming a route here
  /// never needs a server-side config change. An unknown value is logged and
  /// falls through, which is what an app build older than a newly added
  /// destination does — the tap then just brings the app forward.
  bool _handleScheduledNotificationTap(NotificationInteraction interaction) {
    final raw = interaction.payload.raw;
    final deeplink = (raw['deeplink'] ?? '').toString().trim();
    if (deeplink.isEmpty) return false;

    // Only the server's scheduled pushes carry `type` (the NotificationType) —
    // the local return nudge also has a `deeplink` key but no type, so this
    // both attributes the tap and keeps the nudge out of the count. Fired
    // BEFORE the switch on purpose: a destination this build can't route yet
    // (e.g. `explore`) is still a tap worth counting.
    final notiType = (raw['type'] ?? '').toString().trim();
    final courseId = (raw['courseId'] ?? '').toString().trim();
    // Campaign gửi thủ công dùng chung một `noti_type` ('campaign'), nên chỉ
    // `campaign_id` tách được từng cái ra khi đọc số click.
    final campaignId = (raw['campaignId'] ?? '').toString().trim();
    if (notiType.isNotEmpty) {
      unawaited(
        AppService.instance.appTrackingService.trackEvent(TrackingKey.notiTap, parameters: {
          'noti_type': notiType,
          'deeplink': deeplink,
          if (courseId.isNotEmpty) 'course_id': courseId,
          if (campaignId.isNotEmpty) 'campaign_id': campaignId,
        }).catchError((_) {}),
      );
    }

    final navContext = AppConfig.instance.context;
    if (navContext == null) {
      LogDev.warning('Ignoring scheduled notification tap: no navigator context');
      return false;
    }

    switch (deeplink) {
      case 'home':
        HomeRoute().go(navContext);
        return true;

      case 'resume_lesson':
        // Same resume the Live Activity card uses: hand the keypoint to the
        // roadmap and let it open the lesson once course data can resolve it.
        openCourseRoadmapFromLiveActivity(
          courseId,
          keypointId: (raw['keypointId'] ?? '').toString().trim(),
        );
        return true;

      case 'habit_tracker':
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.habit);
        HabitRoute().go(navContext);
        return true;

      case 'new_course':
        _openNewCourseRoadmap(navContext, courseId);
        return true;

      case 'coach':
        // ④ the commitment reminder. The bubble lives on Home, so claiming the
        // tab IS the destination — the sheet is something the reader opens, and
        // springing it open from a notification would break the one rule the
        // whole surface rests on ("it never opens itself").
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.home);
        HomeRoute().go(navContext);
        return true;

      // Ngoài các đích symbolic ở trên, một noti — nhất là campaign gửi thủ
      // công — trỏ được tới bất kỳ khoá nào trong DANH MỤC deeplink dùng chung
      // với link marketing (`deeplink.catalog.ts` bên API). Cùng một bảng đích
      // mà `_navigateToDestination` đã nối đủ, nên thêm một màn cho campaign chỉ
      // cần deploy API: không release app, không release admin.
      //
      // KHÔNG đi qua `navigationFromService`: đường đó bắn thêm `deeplink_open`,
      // và số click của link marketing sẽ lẫn cú chạm push vào. Cú chạm push đã
      // có `noti_tap` ở trên.
      default:
        final destination = DeeplinkDestination.tryFromValue(deeplink);
        if (destination == null) {
          LogDev.warning('Unsupported scheduled notification deeplink: $deeplink');
          return false;
        }
        return _navigateToDestination(
          navContext,
          destination,
          DeeplinkTarget(
            destination: destination,
            rawKey: deeplink,
            params: _notificationDeeplinkParams(raw),
          ),
        );
    }
  }

  /// Tham số cho một đích danh mục mở từ noti: mọi khoá chuỗi trong payload trừ
  /// các khoá điều khiển của chính lớp thông báo.
  ///
  /// Cố ý KHÔNG lọc theo danh sách tên tham số cho phép: mỗi nhánh trong
  /// `_navigateToDestination` chỉ đọc đúng khoá nó cần, nên khoá lạ là vô hại —
  /// mà server bơm thêm tham số (`courseId`, `variant`…) thì không phải chờ một
  /// bản app mới.
  static Map<String, String> _notificationDeeplinkParams(Map<String, dynamic> raw) {
    const controlKeys = <String>{
      NotificationConstants.payloadTypeKey,
      NotificationConstants.payloadDeeplinkKey,
      NotificationConstants.payloadTitleKey,
      NotificationConstants.payloadBodyKey,
      NotificationConstants.payloadNavigateKey,
      NotificationConstants.payloadImageUrlKey,
      NotificationConstants.payloadSourceKey,
      NotificationConstants.payloadMessageIdKey,
      NotificationConstants.payloadNestedMessageKey,
      NotificationConstants.foregroundRenderKey,
      'campaignId',
    };

    final params = <String, String>{};
    raw.forEach((key, value) {
      if (controlKeys.contains(key)) return;
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) params[key] = text;
    });
    return params;
  }

  /// Roadmap source tag for a tap on the daily new-course notification. Unknown
  /// to `remapRoadmapSource`, which buckets it into the generic explore source —
  /// correct, since this is not one of the home surfaces it distinguishes.
  /// A course the Coach offered — ③C's invitation, or ⑦ nhịp 4's keypoint —
  /// tapped from the Coach sheet.
  ///
  /// Same "select the course, claim the branch, then go" sequence as
  /// `_openCourseRoadmap`, but with the LENIENT select: the strict
  /// `trySelectCourseFromCourseId` refuses any course the loaded catalog does
  /// not contain, and here that refusal came out as a dead tap — the sheet
  /// closed, the session ended, and nothing happened (2026-08-25). The server
  /// only ever offers published courses seconds after ranking them, so
  /// "not in the catalog" almost always means a catalog gap, not a vanished
  /// course; `selectCourseFromCourseId` covers that by loading the roadmap
  /// outside the catalog, and the roadmap's own error state covers the rare
  /// truly-gone course better than silence does.
  bool openCourseRoadmapFromCoach(BuildContext navContext, String courseId) {
    if (courseId.trim().isEmpty) return false;
    LogDev.data('[Coach] open course from sheet: $courseId');
    AppDI.injector.get<HomeCubit>().selectCourseFromCourseId(courseId);
    AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource(_coachRoadmapSource);
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
    CourseRoadmapRoute().go(navContext);
    return true;
  }

  static const String _coachRoadmapSource = 'ai_coach';

  static const String _newCourseRoadmapSource = 'notification_new_course';

  /// Nhãn source cho roadmap/explore mở từ một link marketing. Không nằm trong
  /// `remapRoadmapSource`, nên nó rơi vào nhóm explore chung — đúng, vì đây
  /// không phải một trong các bề mặt Home mà hàm đó phân biệt.
  static const String deeplinkRoadmapSource = 'deeplink';

  /// Opens the roadmap of the course a `new_course` notification announced,
  /// falling back to Home when the payload carries no course or the course can no
  /// longer be selected (unpublished since the push, say).
  ///
  /// Deliberately NOT [openCourseRoadmapFromLiveActivity]: that path keeps a
  /// lesson that is already on screen, which is right for "resume what you were
  /// doing" and wrong here — the reader tapped a specific new course and has to
  /// land on it.
  void _openNewCourseRoadmap(BuildContext navContext, String courseId) {
    if (courseId.isEmpty || !_openCourseRoadmap(navContext, courseId, _newCourseRoadmapSource)) {
      HomeRoute().go(navContext);
    }
  }

  /// True while the lesson route — or anything pushed over it, such as the
  /// exercise-result popup or keypoint-complete page — is the current location.
  ///
  /// Reads the router's own configuration rather than `PageCubit`'s tracked
  /// route name: a popup pushed above the lesson re-anchors that name, so it
  /// would report "not in a lesson" exactly when the user is deepest in one.
  /// Matches a whole path segment, so `lesson-list` and `video-lesson` don't
  /// count as the lesson flow.
  bool _isLessonFlowOnScreen(BuildContext navContext) {
    try {
      final uri = GoRouter.of(navContext).routerDelegate.currentConfiguration.uri;
      return uri.pathSegments.contains(RoutePath.lesson);
    } catch (error) {
      LogDev.warning('Could not read current route for live activity resume: $error');
      return false;
    }
  }

  /// Best-effort course title from the full catalog (never throws / returns ''
  /// for an unknown or not-yet-loaded course), mirroring the habit/tracking
  /// resolvers.
  String _resolveLiveActivityCourseName(String courseId) {
    if (courseId.isEmpty) return '';
    try {
      return AppDI.injector.get<HomeCubit>().state.skillsets.resolveCourseByCourseId(courseId).title.text;
    } catch (_) {
      return '';
    }
  }

  /// Bridges a tap on the Live Activity return nudge to `live_nudge_tap` + the
  /// same resume as the deeplink. Every other notification interaction (push
  /// opens, foreground receipts, other locals) is ignored — the local nudge's
  /// notification id is the only match.
  void _handleNotificationInteraction(NotificationInteraction interaction) {
    // Scheduled server notifications (daily remind / unfinished lesson / habit)
    // are recognised by the `deeplink` key their payload carries, not by a
    // notification id — the id is assigned by the OS on delivery.
    if (_handleScheduledNotificationTap(interaction)) return;

    final sourceId = int.tryParse(interaction.payload.sourceId ?? '');
    if (sourceId != liveActivityReturnNudgeNotificationId) return;

    final raw = interaction.payload.raw;
    final courseId = (raw['course_id'] ?? '').toString().trim();
    final keypointId = (raw['keypoint_id'] ?? '').toString().trim();
    var courseName = (raw['course_name'] ?? '').toString().trim();
    if (courseName.isEmpty) courseName = _resolveLiveActivityCourseName(courseId);

    unawaited(
      AppService.instance.appTrackingService.trackEvent(TrackingKey.liveNudgeTap, parameters: {'course_id': courseId, 'course_name': courseName}).catchError((_) {}),
    );

    openCourseRoadmapFromLiveActivity(courseId, keypointId: keypointId);
  }

  void _trackHomeWidgetRoute(
    HomeWidgetDeeplinkTarget target,
    String eventName, {
    String? reason,
    String? resolvedRoute,
  }) {
    final params = {
      ...target.trackingParams,
      if (reason?.isNotEmpty == true) 'reason': reason,
      if (resolvedRoute?.isNotEmpty == true) 'resolved_route': resolvedRoute,
    };
    unawaited(AppService.instance.appTrackingService.trackEvent(eventName, parameters: params));
  }

  void _resolveServiceLink(Uri uri) {
    LogDev.one('ServiceRoute, uri: $uri');
    final String host = uri.host;
    final String path = uri.path;
    final String query = uri.query;
    final String fragment = uri.fragment;
    final Map<String, String> queryParameters = uri.queryParameters;
    _pendingUriKey = uri.toString();
    _serviceRoutePath = resolveDeeplinkRoutePath(uri);
    _serviceRouteQuery = queryParameters;
    _pendingTarget = DeeplinkTarget.tryParse(uri);
    LogDev.one('ServiceRoute, pathValue: $path, query: $query, host: $host, fragment: $fragment, queryParameters: $_serviceRouteQuery');
    LogDev.one('ServiceRoute, pathValueSaved: $_serviceRoutePath, query: $_serviceRouteQuery');
  }

  void _handleServiceRouteParam() {
    _handleServiceRouteHomeTab();
  }

  void _handleServiceRouteHomeTab() {
    if (_serviceRouteQuery['module'] == null) return;
  }

  @override
  Future<void> close() async {
    await _homeWidgetClickSubscription?.cancel();
    await _notificationInteractionSubscription?.cancel();
    await _onboardingExitSubscription?.cancel();
    return super.close();
  }
}

String resolveDeeplinkRoutePath(Uri uri) {
  final path = uri.path.trim();
  if (path.isNotEmpty && path != RoutePath.home) {
    final normalizedPath = normalizeDeeplinkPath(path);
    return normalizedPath;
  }

  final normalizedHost = uri.host.trim().toLowerCase();
  if (normalizedHost.isEmpty || normalizedHost == 'meup.training') {
    return RoutePath.home;
  }

  if (normalizedHost == 'home') {
    return RoutePath.home;
  }

  return '/$normalizedHost';
}

@visibleForTesting
String normalizeDeeplinkPath(String path) {
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty || trimmedPath == RoutePath.home || trimmedPath == '/home') {
    return RoutePath.home;
  }

  return trimmedPath.startsWith('/') ? trimmedPath : '/$trimmedPath';
}


/// Opens an ADMIN-CONFIGURED link (home banner slide, promo popup): the app's
/// own scheme routes inside the app through [DeeplinkCubit]'s table, anything
/// else leaves for the browser/store via `launchURL`.
///
/// The in-app branch deliberately skips the OS round-trip. `launchURL` guards
/// on `canLaunchUrl`, which for a custom scheme needs `meup` listed in iOS's
/// `LSApplicationQueriesSchemes` — it is not, so a `meup://…` link died
/// silently there; and even where it works, bouncing through the OS is a
/// visible app-switch for a screen we can simply open.
Future<void> openConfiguredLink(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.scheme.toLowerCase() == 'meup') {
    AppDI.injector.get<DeeplinkCubit>().navigationFromService(uri);
    return;
  }
  await trimmed.launchURL();
}
