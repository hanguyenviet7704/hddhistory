part of '../../profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profileCubit = context.read<ProfileCubit>();
    final userCubit = context.read<UserCubit>();

    final UserEntity initialUser = profileCubit.state.user.id.isNotEmpty ? profileCubit.state.user : userCubit.state.user;
    if (initialUser.id.isNotEmpty) {
      profileCubit
        ..setUser(initialUser)
        ..loadUser();
    }

    _nameController = TextEditingController(text: initialUser.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onToggleEdit() {
    if (_isEditing) {
      _submitUpdate();
      return;
    }
    setState(() => _isEditing = true);
  }

  void _submitUpdate() {
    final String newName = _nameController.text.trim();
    if (newName.isEmpty) {
      DMessage.showMessage(
        message: context.text.settingProfileFullnameLabel,
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
        message: context.text.settingProfileDesstructiveButton,
        type: MessageType.error,
      );
      return;
    }
    showProfileDeleteDialog(
      context,
      onConfirm: () => context.read<AuthBloc>().add(AuthEvent.deleteAccountPermanently(user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) => previous.status != current.status || previous.user != current.user,
          listener: (context, state) {
            if (state.status == ProfileStatus.loading) {
              EasyLoading.show();
            } else {
              EasyLoading.dismiss();
            }

            if (state.status == ProfileStatus.success) {
              _nameController.text = state.user.name;
              if (_isEditing) setState(() => _isEditing = false);
            }

            if (state.status == ProfileStatus.failure) {
              DMessage.showMessage(
                type: MessageType.error,
                message: state.errorMessage ?? 'Something went wrong',
              );
            }
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final user = state.user;
              final double bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Column(
                children: [
                  ProfileHeader(
                    isEditing: _isEditing,
                    onBack: () => context.pop(),
                    onActionTap: _onToggleEdit,
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _isEditing ? _EditableSection(controller: _nameController, user: user, onSubmit: _submitUpdate) : _ReadonlySection(user: user),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h + bottomPadding),
                    child: ProfileDeleteButton(onTap: () => _handleDeleteAccount(user)),
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
          label: context.text.settingProfileFullnameLabel,
          value: user.name,
        ),
        SizedBox(height: 16.h),
        ProfileFieldDisplay(
          label: context.text.settingProfileEmailLabel,
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
          label: context.text.settingProfileFullnameLabel,
          controller: controller,
          onSubmitted: onSubmit,
        ),
        SizedBox(height: 16.h),
        ProfileReadonlyField(
          label: context.text.settingProfileEmailLabel,
          value: user.email,
        ),
      ],
    );
  }
}
