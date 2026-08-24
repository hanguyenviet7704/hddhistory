part of '../../community.dart';

/// Writing a post (design `S-06`).
///
/// Pops `true` when something was published, so the caller knows to refresh
/// rather than guessing.
class CommunityComposePage extends StatefulWidget {
  const CommunityComposePage({super.key});

  @override
  State<CommunityComposePage> createState() => _CommunityComposePageState();
}

class _CommunityComposePageState extends State<CommunityComposePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CommunityComposeCubit>().loadTopics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocBuilder<CommunityComposeCubit, CommunityComposeState>(
      builder: (context, state) {
        final cubit = context.read<CommunityComposeCubit>();

        return Scaffold(
          backgroundColor: AppCustomColor.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppCustomColor.backgroundWhite,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(false),
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close, size: 20.sp, color: AppCustomColor.textPrimary),
            ),
            title: AppText(
              l10n.composeTitle,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: GestureDetector(
                  onTap: state.canSubmit
                      ? () async {
                          final post = await cubit.submit();
                          if (!context.mounted) return;

                          if (post == null) {
                            // cubit.state, not the `state` this builder closed
                            // over: submit() has emitted since then, and that
                            // emit is where the server's reason lives.
                            DMessage.showMessage(
                              message: cubit.state.errorMessage ?? l10n.errorBody,
                              type: MessageType.error,
                            );
                            return;
                          }

                          Navigator.of(context).maybePop(true);
                        }
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: state.canSubmit
                            ? AppCustomColor.brandPrimary
                            : AppCustomColor.buttonDisable,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: AppText(
                        l10n.composeSubmit,
                        style: AppStyle.textBold12.copyWith(
                          color: state.canSubmit
                              ? AppCustomColor.textWhite
                              : AppCustomColor.communityMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
            children: [
              AppText(
                l10n.composeGroupLabel,
                style: AppStyle.textBold10.copyWith(
                  color: AppCustomColor.communityMuted,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _GroupChip(
                    label: l10n.composeNoGroup,
                    isActive: state.topicId == null,
                    onTap: () => cubit.setTopic(null),
                  ),
                  ...state.topics.map(
                    (topic) => _GroupChip(
                      label: topic.name,
                      isActive: state.topicId == topic.id,
                      onTap: () => cubit.setTopic(topic.id),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _controller,
                minLines: 6,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.55,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.composeBodyHint,
                  hintStyle: AppStyle.text14.copyWith(color: AppCustomColor.communityMuted),
                ),
                onChanged: cubit.setBody,
              ),
              SizedBox(height: 16.h),
              _ImageStrip(state: state),
              if (state.attachedCourseId != null) ...[
                SizedBox(height: 16.h),
                _AttachedCourseRow(
                  title: state.attachedCourseTitle ?? '',
                  onRemove: cubit.removeAttachedCourse,
                ),
              ],
              SizedBox(height: 20.h),
              const _IdentityNote(),
            ],
          ),
        );
      },
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(
            color: isActive ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
          ),
        ),
        child: AppText(
          label,
          style: AppStyle.textBold12.copyWith(
            color: isActive ? AppCustomColor.textWhite : AppCustomColor.streakTextMuted,
          ),
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.state});

  final CommunityComposeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityComposeCubit>();

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        ...state.images.map(
          (url) => Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: DCachedImage(url: url, width: 84.w, height: 84.w, fit: BoxFit.cover),
              ),
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: () => cubit.removeImage(url),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 22.w,
                    height: 22.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppCustomColor.textPrimary,
                    ),
                    child: Icon(Icons.close, size: 12.sp, color: AppCustomColor.textWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.images.length < CommunityComposeCubit.maxImages)
          GestureDetector(
            onTap: state.isUploadingImage ? null : () => _pickImage(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 84.w,
              height: 84.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppCustomColor.borderSecondary),
              ),
              child: state.isUploadingImage
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20.sp,
                          color: AppCustomColor.streakTextMuted,
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          l10n.composeAddImage,
                          style: AppStyle.text10.copyWith(
                            color: AppCustomColor.streakTextMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final cubit = context.read<CommunityComposeCubit>();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    await cubit.addImage(picked.path);
  }
}

class _AttachedCourseRow extends StatelessWidget {
  const _AttachedCourseRow({required this.title, required this.onRemove});

  final String title;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundBrandSoft,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 20.sp, color: AppCustomColor.streakActive),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
                  maxLines: 1,
                ),
                AppText(
                  l10n.composeCourseAttached,
                  style: AppStyle.text10.copyWith(color: AppCustomColor.streakTextMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close, size: 16.sp, color: AppCustomColor.streakTextMuted),
          ),
        ],
      ),
    );
  }
}

/// "Đăng với tên X" — the design says this out loud, and it should: the forum
/// runs on real names, and a writer deserves to know that before posting.
class _IdentityNote extends StatelessWidget {
  const _IdentityNote();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (state) => state.user.name,
      builder: (context, name) => Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            CommunityAvatar(author: CommunityAuthorEntity(name: name), size: 32),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.composePostingAs(name: name),
                    style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  AppText(
                    l10n.composeVisibilityHint,
                    style: AppStyle.text10.copyWith(color: AppCustomColor.streakTextMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
