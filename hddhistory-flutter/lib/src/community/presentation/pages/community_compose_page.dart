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
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CommunityComposeCubit>().loadTopics();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// Opens the library picker and applies whichever kind of thing was picked.
  ///
  /// The cap is enforced by the cubit and answered HERE with the design's toast:
  /// the cubit has no toast to show, and a pick that silently does nothing reads
  /// as a broken row.
  void _openAttachSheet() {
    final cubit = context.read<CommunityComposeCubit>();
    final l10n = context.l10n.community;

    showCommunityAttachSheet(
      context,
      onPickCourse: (course) {
        if (cubit.state.attachedCourseId == null && cubit.state.isAttachmentFull) {
          DMessage.showMessage(
            message: l10n.attachLimitToast,
            type: MessageType.info,
          );
          return;
        }
        cubit.attachCourse(courseId: course.id, title: course.title.text);
      },
      onPickCard: (card) {
        final attached = cubit.attachCard(communityCardFromSavedCard(card));
        if (attached) return;

        DMessage.showMessage(
          message: l10n.attachLimitToast,
          type: MessageType.info,
        );
      },
    );
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
            // The design closes the header with a hairline; without it the page
            // and the bar are one white field and the title floats.
            shape: const Border(
              bottom: BorderSide(color: AppCustomColor.communityRule),
            ),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(false),
              behavior: HitTestBehavior.opaque,
              // Center, or the glyph inflates: AppBar hands `leading` a TIGHT
              // 56-wide box, and SvgPicture's own width/height lose to it.
              child: Center(
                child: CommunityGlyph(
                  AppAsset.svg.app.icCommunityClose,
                  size: 22,
                  color: AppCustomColor.textPrimary,
                ),
              ),
            ),
            title: AppText(
              l10n.composeTitle,
              style: AppStyle.textBold16.copyWith(
                fontSize: 15.sp,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
                  children: [
                    _RoomPicker(state: state),
                    SizedBox(height: 18.h),
                    _ComposeFields(
                      subjectController: _subjectController,
                      bodyController: _bodyController,
                    ),
                    if (state.attachedCourseId != null) ...[
                      SizedBox(height: 14.h),
                      CommunityAttachedCourseCard(
                        courseId: state.attachedCourseId!,
                        onRemove: cubit.removeAttachedCourse,
                      ),
                    ],
                    if (state.attachedCard != null) ...[
                      SizedBox(height: 14.h),
                      CommunityInsightCard(
                        card: state.attachedCard!,
                        onRemove: cubit.removeAttachedCard,
                      ),
                    ],
                    if (state.images.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      _ImagePreviews(state: state),
                    ],
                    SizedBox(height: 16.h),
                    // Photo and paperclip live in the PAGE, next to what they
                    // add, not in the bottom bar — the bar is for decisions
                    // about the post as a whole (design `S-06`).
                    _ComposeAttachRow(state: state, onAttach: _openAttachSheet),
                    SizedBox(height: 18.h),
                    // Hidden while anonymous is on: "Đăng với tên X" beside a
                    // lit "Ẩn danh" toggle contradicts itself.
                    if (!state.isAnonymous) const _IdentityNote(),
                  ],
                ),
              ),
              _ComposeBottomBar(state: state),
            ],
          ),
        );
      },
    );
  }
}

/// The bar pinned under the page: anonymity, then Đăng (design `S-06`).
///
/// Both are decisions about the post as a whole, and "Ẩn danh" in particular has
/// to be visible at the moment the writer reaches for Đăng — a privacy switch
/// that has scrolled away is a privacy switch nobody checks. Đăng sits HERE
/// rather than in the header for the same reason: the two are read together.
class _ComposeBottomBar extends StatelessWidget {
  const _ComposeBottomBar({required this.state});

  final CommunityComposeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityComposeCubit>();

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 9.h),
      decoration: const BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        border: Border(top: BorderSide(color: AppCustomColor.communityRule)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Spacer(),
            _AnonymousToggle(isOn: state.isAnonymous, onTap: cubit.toggleAnonymous),
            SizedBox(width: 10.w),
            _SubmitButton(state: state),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state});

  final CommunityComposeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityComposeCubit>();

    return GestureDetector(
      onTap: state.canSubmit
          ? () async {
              final post = await cubit.submit();
              if (!context.mounted) return;

              if (post == null) {
                // cubit.state, not the `state` this widget closed over:
                // submit() has emitted since, and that emit is where the
                // server's reason lives.
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
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: state.canSubmit ? AppCustomColor.brandPrimary : AppCustomColor.buttonDisable,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: AppText(
          l10n.composeSubmit,
          style: AppStyle.textBold12.copyWith(
            fontSize: 13.sp,
            color: state.canSubmit ? AppCustomColor.textWhite : AppCustomColor.communityMuted,
          ),
        ),
      ),
    );
  }
}

/// Title and body, as bare fields with no boxes — the way the design draws
/// them. This is a page you write on, and a bordered input turns it into a form.
class _ComposeFields extends StatelessWidget {
  const _ComposeFields({required this.subjectController, required this.bodyController});

  final TextEditingController subjectController;
  final TextEditingController bodyController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityComposeCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: subjectController,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: AppStyle.textBold18.copyWith(
            color: AppCustomColor.textPrimary,
            height: 1.28,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: l10n.composeSubjectHint,
            hintStyle: AppStyle.textBold18.copyWith(
              color: AppCustomColor.communityPlaceholder,
              height: 1.28,
              letterSpacing: -0.2,
            ),
          ),
          onChanged: cubit.setSubject,
        ),
        SizedBox(height: 22.h),
        TextField(
          controller: bodyController,
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: AppStyle.text14.copyWith(
            fontSize: 13.5.sp,
            color: AppCustomColor.textPrimary,
            height: 1.55,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: l10n.composeBodyHint,
            hintStyle: AppStyle.text14.copyWith(
              fontSize: 13.5.sp,
              color: AppCustomColor.communityPlaceholder,
              height: 1.55,
            ),
          ),
          onChanged: cubit.setBody,
        ),
      ],
    );
  }
}

/// Photo and paperclip, the two ways to attach something (design `S-06`).
class _ComposeAttachRow extends StatelessWidget {
  const _ComposeAttachRow({required this.state, required this.onAttach});

  final CommunityComposeState state;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return Row(
      children: [
        Semantics(
          label: l10n.composeAddImage,
          button: true,
          child: GestureDetector(
            onTap: state.isUploadingImage ? null : () => _pickImage(context),
            behavior: HitTestBehavior.opaque,
            child: state.isUploadingImage
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : CommunityGlyph(
                    AppAsset.svg.app.icCommunityPhoto,
                    size: 22,
                    color: AppCustomColor.communityMuted,
                  ),
          ),
        ),
        SizedBox(width: 14.w),
        Semantics(
          label: l10n.attachSheetTitle,
          button: true,
          child: GestureDetector(
            onTap: onAttach,
            behavior: HitTestBehavior.opaque,
            child: CommunityGlyph(
              AppAsset.svg.app.icCommunityAttach,
              size: 22,
              color: AppCustomColor.communityMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// The room chip and its dropdown (design `S-06`).
///
/// A chip that opens a menu rather than a row of chips: a reader can be in a
/// dozen rooms, and a wrap of a dozen chips pushes the title field off the first
/// screen of a page whose whole job is writing.
class _RoomPicker extends StatelessWidget {
  const _RoomPicker({required this.state});

  final CommunityComposeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;
    final cubit = context.read<CommunityComposeCubit>();
    final selected = state.selectedTopic;
    final hasRoom = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: cubit.toggleRoomPicker,
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 34.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: hasRoom ? AppCustomColor.brandPrimary50 : AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(99.r),
                border: Border.all(
                  color: hasRoom ? AppCustomColor.brandPrimary200 : AppCustomColor.borderSecondary,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommunityGlyph(
                    AppAsset.svg.app.icCommunityRoom,
                    size: 14,
                    color: hasRoom ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                  ),
                  SizedBox(width: 7.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 220.w),
                    child: AppText(
                      hasRoom ? selected.name : l10n.composeRoomPick,
                      style: AppStyle.textBold12.copyWith(
                        color: hasRoom ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  // Rotated rather than swapped for an "up" glyph: the design
                  // ships one chevron, and turning it says "this menu is the
                  // thing that opened" instead of "a different control".
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 160),
                    turns: state.isRoomPickerOpen ? 0.5 : 0,
                    child: CommunityGlyph(
                      AppAsset.svg.app.icCommunityChevronDown,
                      size: 12,
                      color: hasRoom ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.isRoomPickerOpen) ...[
          SizedBox(height: 8.h),
          Container(
            width: 250.w,
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppCustomColor.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.textPrimary.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(9.w, 7.h, 9.w, 5.h),
                  child: AppText(
                    l10n.composeRoomSectionLabel,
                    style: AppStyle.textBold10.copyWith(
                      color: AppCustomColor.communityPlaceholder,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                _RoomOption(
                  label: l10n.composeNoGroup,
                  isPicked: state.topicId == null,
                  onTap: () => cubit.setTopic(null),
                ),
                ...state.topics.map(
                  (topic) => _RoomOption(
                    label: topic.name,
                    isPicked: state.topicId == topic.id,
                    onTap: () => cubit.setTopic(topic.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({
    required this.label,
    required this.isPicked,
    required this.onTap,
  });

  final String label;
  final bool isPicked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 9.w),
        decoration: BoxDecoration(
          color: isPicked ? AppCustomColor.backgroundGray : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                label,
                style: AppStyle.textBold12.copyWith(
                  color: isPicked ? AppCustomColor.textPrimary : AppCustomColor.streakTextMuted,
                ),
                maxLines: 1,
              ),
            ),
            if (isPicked)
              CommunityGlyph(
                AppAsset.svg.app.icCommunityCheck,
                size: 14,
                color: AppCustomColor.brandPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Ẩn danh" with its switch.
///
/// One tap target for the label and the switch together — two adjacent hit
/// areas that do the same thing is how a reader ends up thinking one of them
/// does something else.
class _AnonymousToggle extends StatelessWidget {
  const _AnonymousToggle({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.community;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: l10n.composeAnonymous,
        toggled: isOn,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.only(left: 12.w, right: 5.w),
          decoration: BoxDecoration(
            color: isOn ? AppCustomColor.brandPrimary50 : AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(99.r),
            border: Border.all(
              color: isOn ? AppCustomColor.brandPrimary200 : AppCustomColor.borderSecondary,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                l10n.composeAnonymous,
                style: AppStyle.textBold12.copyWith(
                  color: isOn ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted,
                ),
              ),
              SizedBox(width: 7.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36.w,
                height: 22.h,
                padding: EdgeInsets.all(2.w),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: isOn ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
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

/// The photos already attached (design `S-06`).
///
/// Previews only — the way to ADD one is the photo glyph in
/// [_ComposeAttachRow], where the design puts it. A second "+" tile inside the
/// strip is a duplicate affordance for the same job.
class _ImagePreviews extends StatelessWidget {
  const _ImagePreviews({required this.state});

  final CommunityComposeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityComposeCubit>();

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: state.images
          .map(
            (url) => Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: DCachedImage(url: url, width: 108.w, height: 108.w, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () => cubit.removeImage(url),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppCustomColor.textPrimary.withValues(alpha: 0.6),
                      ),
                      child: CommunityGlyph(
                        AppAsset.svg.app.icCommunityClose,
                        size: 12,
                        color: AppCustomColor.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

/// Picks a photo, refusing past the attachment cap with the design's toast —
/// the cubit has no toast to show, and a pick that silently does nothing reads
/// as a broken button.
Future<void> _pickImage(BuildContext context) async {
  final cubit = context.read<CommunityComposeCubit>();
  final l10n = context.l10n.community;

  if (cubit.state.isAttachmentFull) {
    DMessage.showMessage(message: l10n.attachLimitToast, type: MessageType.info);
    return;
  }

  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  await cubit.addImage(picked.path);
}
