part of '../../onboard_v2.dart';

class OnboardV2NamePage extends StatefulWidget {
  const OnboardV2NamePage({super.key});

  @override
  State<OnboardV2NamePage> createState() => _OnboardV2NamePageState();
}

class _OnboardV2NamePageState extends State<OnboardV2NamePage> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<OnboardV2Cubit>().state.name);
    _nameFocusNode = FocusNode();
    _nameController.addListener(_syncNameToCubit);
    // This page is first built the moment the P1→P2 PageView animation (340ms)
    // starts, so focusing on the next frame raised the keyboard mid-transition —
    // keyboard slide + page scroll + first paint stacked into visible jank on
    // both screens. Wait the transition out, then bring the keyboard up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (context.read<OnboardV2Cubit>().state.currentPage != OnboardV2PageStep.p2Name) return;
        _nameFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController
      ..removeListener(_syncNameToCubit)
      ..dispose();
    super.dispose();
  }

  void _syncNameToCubit() {
    final cubit = context.read<OnboardV2Cubit>();
    if (cubit.state.name == _nameController.text) return;
    cubit.updateName(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    _syncControllerFromState(state.name);

    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 1,
        totalSegments: _onboardV2TotalProgressSegments,
        pageStep: OnboardV2PageStep.p2Name,
        showBack: false,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueName ? _continueFromName : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          32.verticalSpace,
          AppAsset.icons.app.icWaveHand.image(
            key: const Key('onboard_v2_name_wave_hand'),
            width: 32.w,
            height: 32.w,
            fit: BoxFit.contain,
          ),
          18.verticalSpace,
          AppText(
            onbCopy(state.onboardData, 'onboardingV2P2HeadingPrefix', fallback: onboardingL10n.onboardingV2P2HeadingPrefix),
            overflow: TextOverflow.visible,
            style: onboardV2HeadingStyle(fontSize: 26).copyWith(color: AppCustomColor.textPrimary),
          ),
          OnboardV2GradientText(
            onbCopy(state.onboardData, 'onboardingV2P2HeadingHighlight', fallback: onboardingL10n.onboardingV2P2HeadingHighlight),
            style: onboardV2HeadingStyle(fontSize: 26),
          ),
          12.verticalSpace,
          AppText(
            onbCopy(state.onboardData, 'onboardingV2P2Subtitle', fallback: onboardingL10n.onboardingV2P2Subtitle),
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          32.verticalSpace,
          SizedBox(
            height: 80.w,
            child: TextField(
              key: const Key('onboard_v2_name_input'),
              controller: _nameController,
              focusNode: _nameFocusNode,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              scrollPadding: EdgeInsets.only(bottom: 180.h),
              style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, height: 1.5),
              onSubmitted: (_) => _continueFromName(),
              decoration: InputDecoration(
                hintText: onbCopy(state.onboardData, 'onboardingV2P2InputHint', fallback: onboardingL10n.onboardingV2P2InputHint),
                hintStyle: AppStyle.text16.copyWith(color: AppCustomColor.textTertiary, height: 1.5),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                filled: true,
                fillColor: AppCustomColor.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppCustomColor.borderSecondary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppCustomColor.borderSecondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppCustomColor.brandPrimary, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueFromName() {
    final cubit = context.read<OnboardV2Cubit>();
    if (!cubit.state.canContinueName) return;

    _nameFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
    cubit.continueFromName();
  }

  void _syncControllerFromState(String name) {
    if (_nameController.text == name) return;

    final offset = math.min(_nameController.selection.baseOffset, name.length);
    _nameController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: math.max(offset, 0)),
    );
  }
}
