part of '../../home.dart';

class HomeHeaderWidget extends StatefulWidget {
  const HomeHeaderWidget({super.key});

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  bool _isOpeningStreakPopup = false;
  int _debugHomeWidgetScenarioIndex = 0;

  Future<void> _openStreakPopup(int currentStreak) async {
    if (_isOpeningStreakPopup) return;

    setState(() => _isOpeningStreakPopup = true);
    AppService.instance.appTrackingService.trackHomeStreakChipClick(currentStreak: currentStreak);

    try {
      await const HomeLearningStreakRoute().push(context);
    } finally {
      if (mounted) {
        setState(() => _isOpeningStreakPopup = false);
      }
    }
  }

  Future<void> _debugApplyNextHomeWidgetScenario() async {
    if (!kDebugMode) return;

    final scenarioIndex = _debugHomeWidgetScenarioIndex;
    _debugHomeWidgetScenarioIndex = (_debugHomeWidgetScenarioIndex + 1) % 3;

    try {
      switch (scenarioIndex) {
        case 0:
          await _debugApplyHomeWidgetPayloads(
            message: 'Home widget fake: no started course',
            payloads: await _buildDebugNoStartedHomeWidgetPayloads(),
          );
          break;
        case 1:
          await _debugApplyHomeWidgetPayloads(
            message: 'Home widget fake: done all courses',
            payloads: await _buildDebugDoneAllHomeWidgetPayloads(),
          );
          break;
        default:
          await AppDI.injector.get<ClearHomeWidgetsUseCase>()(unit).run();
          await AppDI.injector
              .get<SyncHomeWidgetsUseCase>()(
                HomeWidgetSyncParams(localeCode: _debugLocaleCode()),
              )
              .run();
          _showDebugSnackBar('Home widget reset: synced from API');
      }
    } catch (error) {
      LogDev.error('Home widget debug fake failed: $error');
      _showDebugSnackBar('Home widget fake failed: $error', type: MessageType.error);
    }
  }

  Future<void> _debugApplyHomeWidgetPayloads({
    required String message,
    required List<HomeWidgetPayload> payloads,
  }) async {
    final bridge = AppDI.injector.get<HomeWidgetBridge>();

    await AppDI.injector.get<ClearHomeWidgetsUseCase>()(unit).run();
    await bridge.prepareStaticAssets();
    for (final payload in payloads) {
      await bridge.savePayload(payload);
      await bridge.updateWidget(payload.widgetType);
    }

    _showDebugSnackBar(message);
  }

  void _showDebugSnackBar(String message, {MessageType type = MessageType.success}) {
    if (!mounted) return;
    context.showDSnackBar(
      message: message,
      type: type,
      duration: const Duration(seconds: 2),
    );
  }

  String _greetingPrefix(BuildContext context) {
    return context.l10n.home.homeGreetingPrefix;
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = context.select((LearningStreakCubit cubit) => cubit.state.selectedItem.currentStreak);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // Figma 11634:15343 — light periwinkle (#B0ACF5) across the top ~60%,
        // then deepening to #8579F3 toward the bottom. (The app previously did
        // the reverse — fading to a washed-out pale lavender — which made the
        // header look flat and the quote card read as near-white.)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB0ACF5), Color(0xFFB0ACF5), Color(0xFF8579F3)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: BlocSelector<ProfileCubit, ProfileState, String>(
                  selector: (state) => state.user.name,
                  builder: (context, username) {
                    final firstName = username.trim().split(' ').first;

                    final greetingWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${_greetingPrefix(context)}, $firstName',
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textPrimary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.verticalSpace,
                        AppText(
                          context.l10n.home.homeGreetingQuestion,
                          style: AppStyle.textBold20.copyWith(
                            color: AppCustomColor.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );

                    if (!kDebugMode) return greetingWidget;

                    // Debug-only manual QA hook. Remove after home widget state checks.
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _debugApplyNextHomeWidgetScenario,
                      child: greetingWidget,
                    );
                  },
                ),
              ),
              10.horizontalSpace,
              StreakHomeChip(
                currentStreak: currentStreak,
                onTap: () => _openStreakPopup(currentStreak),
              ),
            ],
          ),
          16.verticalSpace,
          // Quote card
          _HomeInlineQuoteCard(),
        ],
      ),
    );
  }
}

/// Inline quote card rendered inside the purple header.
///
/// Shows the dynamic quote from [HomeCubit] when available, otherwise renders
/// nothing so the header collapses gracefully.
class _HomeInlineQuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, QuoteEntity?>(
      selector: (state) => state.quote,
      builder: (context, quote) {
        final quoteText = (quote != null && quote.content.text.isNotEmpty)
            ? quote.content.text
            : null;

        if (quoteText == null) return const SizedBox.shrink();

        return Semantics(
          label: context.l10n.home.homeQuoteLabel,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              // Figma 11634:15357 — a frosted, translucent-WHITE card (radial
              // white 0.9 → 0.5) sitting over the lavender header, not the old
              // solid purple fill. Lets the header gradient glow through.
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.9),
                radius: 1.5,
                // Design card samples: #F2F1FC (top-left highlight) → #E7E5FC
                // over the periwinkle bg ≈ white 0.9 → 0.68.
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.68),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Quote text — Medium (w500), centered (Figma node 10725:31459).
                // Inset horizontally so wrapped lines never run under the
                // top-right quote mark.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppText(
                      quoteText,
                      textAlign: TextAlign.center,
                      style: AppStyle.text13.copyWith(
                        color: AppCustomColor.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.75,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Quote mark — hugs the top-right corner (Figma: 28px, 30%
                // opacity, rotated 180°, ~6px from the card's top/right edge).
                // Painted last so it sits above the text, never clipped.
                Positioned(
                  top: -10.h,
                  right: -2.w,
                  child: Opacity(
                    opacity: 0.30,
                    child: Transform.rotate(
                      angle: 3.14159, // 180° in radians
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 28.w,
                        color: AppCustomColor.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
