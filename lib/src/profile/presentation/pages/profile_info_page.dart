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
      _submitUpdate();
      return;
    }
    _isEditingNotifier.value = true;
  }

  void _submitUpdate() {
    final String newName = _nameController.text.trim();
    if (newName.isEmpty) {
      DMessage.showMessage(
        message: context.text.setting.settingProfileFullnameLabel,
        type: MessageType.error,
      );
      return;
    }
    final profileCubit = context.read<ProfileCubit>();
    final user = profileCubit.state.user;
    profileCubit.updateUser(user.copyWith(name: newName));
  }

  void _handleDeleteAccount(UserEntity user) {
    if (user.id.isEmpty) {
      DMessage.showMessage(
        message: context.text.setting.settingProfileDesstructiveButton,
        type: MessageType.error,
      );
      return;
    }
    ProfileDeleteDialog.show(
      context,
      onConfirm: () {
        context.read<AuthBloc>().add(AuthEvent.deleteAccountPermanently(user.id));
        context.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

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
            BlocListener<IapCubit, IapState>(
              listenWhen: (previous, current) => previous.status != current.status && current.status == MonetizationStatus.purchaseSuccess,
              listener: (context, state) {
                PaywallSuccessPurchasePopup.show(context);
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
                  if (!isEditing)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h + bottomPadding),
                      child: BlocSelector<ProfileCubit, ProfileState, UserEntity>(
                        selector: (state) => state.user,
                        builder: (context, user) {
                          if (user.anonymous) return const SizedBox.shrink();
                          return ProfileDeleteButton(onTap: () => _handleDeleteAccount(user));
                        },
                      ),
                    ),
                ],
              );
            },
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
          label: context.text.setting.settingProfileFullnameLabel,
          value: user.name,
        ),
        SizedBox(height: 16.h),
        ProfileFieldDisplay(
          label: context.text.setting.settingProfileEmailLabel,
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
          label: context.text.setting.settingProfileFullnameLabel,
          controller: controller,
          onSubmitted: onSubmit,
        ),
        SizedBox(height: 16.h),
        ProfileReadonlyField(
          label: context.text.setting.settingProfileEmailLabel,
          value: user.email,
        ),
      ],
    );
  }
}
