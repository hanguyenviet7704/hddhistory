part of '../../onboard_v2.dart';

class OnboardV2NamePage extends StatefulWidget {
  const OnboardV2NamePage({super.key});

  @override
  State<OnboardV2NamePage> createState() => _OnboardV2NamePageState();
}

class _OnboardV2NamePageState extends State<OnboardV2NamePage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<OnboardV2Cubit>().state.name);
    _nameController.addListener(_syncNameToCubit);
  }

  @override
  void dispose() {
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
      header: OnboardV2ProgressHeader(activeSegments: 0, showBack: false, onBack: cubit.goBack),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueName ? cubit.continueFromName : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          32.verticalSpace,
          Icon(Icons.waving_hand_rounded, size: 32.w, color: AppCustomColor.brandPrimary),
          18.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P2HeadingPrefix,
            overflow: TextOverflow.visible,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(onboardingL10n.onboardingV2P2HeadingHighlight, style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4)),
          12.verticalSpace,
          AppText(onboardingL10n.onboardingV2P2Subtitle, style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary)),
          32.verticalSpace,
          TextField(
            key: const Key('onboard_v2_name_input'),
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: onboardingL10n.onboardingV2P2InputHint,
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
        ],
      ),
    );
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
