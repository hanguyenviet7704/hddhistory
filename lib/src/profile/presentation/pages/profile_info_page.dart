part of '../../profile.dart';

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileInfoView();
  }
}

class _ProfileInfoView extends StatefulWidget {
  const _ProfileInfoView();

  @override
  State<_ProfileInfoView> createState() => _ProfileInfoViewState();
}

class _ProfileInfoViewState extends State<_ProfileInfoView> {
  late final TextEditingController _nameController;
  late final ValueNotifier<bool> _isEditingNotifier;

  @override
  void initState() {
    super.initState();
    final profileCubit = context.read<ProfileCubit>();
    final UserEntity initialUser = profileCubit.state.user;
    _nameController = TextEditingController(text: initialUser.name);
    _isEditingNotifier = ValueNotifier(false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _isEditingNotifier.dispose();
    super.dispose();
  }

  void _onToggleEdit() {
    if (_isEditingNotifier.value) {
      AppService.instance.appTrackingService.trackSettingProfileDoneClick();
      _submitUpdate();
      return;
    }
    AppService.instance.appTrackingService.trackSettingProfileEditClick();
    _isEditingNotifier.value = true;
  }

  void _submitUpdate() {
    final String newName = _nameController.text.trim();
    if (newName.isEmpty) {
      DMessage.showMessage(
        message: context.l10n.setting.settingProfileFullnameLabel,
        type: MessageType.error,
      );
      return;
    }
    final profileCubit = context.read<ProfileCubit>();
    final user = profileCubit.state.user;
    profileCubit.updateUser(user.copyWith(name: newName));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileCubit, ProfileState>(
              listenWhen: (previous, current) => previous.status != current.status || previous.user != current.user,
              listener: (context, state) {
                if (state.status == ProfileStatus.loading) {
                  EasyLoading.show();
                } else {
                  EasyLoading.dismiss();
                }

                if (state.status == ProfileStatus.success) {
                  _nameController.text = state.user.name;
                  if (_isEditingNotifier.value) _isEditingNotifier.value = false;
                }

                if (state.status == ProfileStatus.failure) {
                  DMessage.showMessage(
                    type: MessageType.error,
                    message: state.errorMessage ?? 'Something went wrong',
                  );
                }
              },
            ),
          ],
          child: ValueListenableBuilder<bool>(
            valueListenable: _isEditingNotifier,
            builder: (context, isEditing, _) {
              return Column(
                children: [
                  ProfileHeader(
                    isEditing: isEditing,
                    onBack: () => context.back(),
                    onActionTap: _onToggleEdit,
                  ),
                  Expanded(
                    child: BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                      selector: (state) => state.user,
                      builder: (context, user) {
                        return ListView(
                          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Design `6 · Profile` scopes this screen as
                            // "Edit profile (name + avatar)". The avatar saves
                            // by itself on pick — it does not wait for the
                            // Edit/Done cycle the name field uses.
                            Center(child: _AvatarEditor(user: user)),
                            SizedBox(height: 28.h),
                            isEditing
                                ? _EditableSection(
                                    controller: _nameController,
                                    user: user,
                                    onSubmit: _submitUpdate,
                                  )
                                : _ReadonlySection(user: user),
                          ],
                        );
                      },
                    ),
                  ),
                  // No delete-account button here any more (product call,
                  // 2026-08-13). Only the ENTRY POINT is gone: the confirm
                  // dialog, `AuthBloc.deleteAccountPermanently` and the API
                  // behind it are untouched, so restoring it is one widget.
                  // Worth knowing before a store submission — App Store
                  // guideline 5.1.1(v) requires an in-app way to delete an
                  // account for any app that lets you create one.
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The avatar with a camera badge; tapping anywhere on it opens the
/// source sheet. Reuses [_ProfileAvatar] (same library) at edit-screen size so
/// the photo/initial fallback logic stays in one place.
class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.setting.settingProfileChangePhoto,
      child: GestureDetector(
        key: const Key('profile-avatar-editor'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          _AvatarSourceSheet.show(context);
        },
        child: SizedBox(
          width: 96.w,
          height: 96.w,
          child: Stack(
            children: [
              _ProfileAvatar(user: user, dimension: 96, initialFontSize: 36),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppCustomColor.brandPrimary,
                    border: Border.all(
                      color: AppCustomColor.backgroundWhite,
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 15.w,
                    color: AppCustomColor.backgroundWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Camera-or-library chooser. Resolves [ProfileCubit] through DI rather than
/// context.read: a modal sheet lives on the root navigator, above the route's
/// providers (the gift-popup crash was this exact mistake).
class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppCustomColor.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => const _AvatarSourceSheet(),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final XFile? picked;
    try {
      // Downscaled on pick, mirroring the study-theme background picker: the
      // upload endpoint has no image-size cap of its own, and an avatar never
      // needs more than this.
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
    } catch (error) {
      // Camera/photos permission refused at the OS level. The system dialog
      // has already told the user; nothing useful to add here.
      LogDev.warning('[AvatarEditor] pick failed: $error');
      return;
    }
    if (picked == null) return;
    unawaited(AppDI.injector.get<ProfileCubit>().updateAvatar(File(picked.path)));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.setting;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, bottomPadding > 0 ? 0 : 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              l10n.settingProfileChangePhoto,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
            SizedBox(height: 8.h),
            _AvatarSourceOption(
              key: const Key('avatar-source-camera'),
              icon: Icons.photo_camera_outlined,
              label: l10n.settingProfileTakePhoto,
              onTap: () => _pick(context, ImageSource.camera),
            ),
            _AvatarSourceOption(
              key: const Key('avatar-source-library'),
              icon: Icons.photo_outlined,
              label: l10n.settingProfileChooseFromLibrary,
              onTap: () => _pick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSourceOption extends StatelessWidget {
  const _AvatarSourceOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, size: 22.w, color: AppCustomColor.textSecondary),
              SizedBox(width: 14.w),
              Expanded(
                child: AppText(
                  label,
                  style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadonlySection extends StatelessWidget {
  const _ReadonlySection({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldDisplay(
          label: context.l10n.setting.settingProfileFullnameLabel,
          value: user.name,
        ),
        SizedBox(height: 16.h),
        ProfileFieldDisplay(
          label: context.l10n.setting.settingProfileEmailLabel,
          value: user.email,
        ),
      ],
    );
  }
}

class _EditableSection extends StatelessWidget {
  const _EditableSection({
    required this.controller,
    required this.user,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final UserEntity user;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileEditableField(
          label: context.l10n.setting.settingProfileFullnameLabel,
          controller: controller,
          onSubmitted: onSubmit,
        ),
        SizedBox(height: 16.h),
        ProfileReadonlyField(
          label: context.l10n.setting.settingProfileEmailLabel,
          value: user.email,
        ),
      ],
    );
  }
}
