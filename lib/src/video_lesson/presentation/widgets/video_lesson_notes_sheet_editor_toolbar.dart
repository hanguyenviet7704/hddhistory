part of '../../video_lesson.dart';

const _videoLessonTextSymbolIconAsset = 'assets/svg/app/ic_text_symbol.svg';
const _videoLessonBulletIconAsset = 'assets/svg/app/ic_bullet.svg';
const _videoLessonBulletNumberIconAsset = 'assets/svg/app/ic_bullet_number.svg';

class _VideoLessonNoteEditorToolbar extends StatelessWidget {
  const _VideoLessonNoteEditorToolbar({
    required this.controller,
    required this.focusNode,
  });

  final quill.QuillController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selectionStyle = controller.getSelectionStyle().attributes;
        final activeListType = selectionStyle[quill.Attribute.list.key]?.value as String?;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _VideoLessonToolbarIcon(
                icon: Icons.format_bold_rounded,
                selected: selectionStyle.containsKey(quill.Attribute.bold.key),
                onTap: () => _toggleNoteInlineAttribute(
                  controller: controller,
                  focusNode: focusNode,
                  attribute: quill.Attribute.bold,
                ),
              ),
              8.horizontalSpace,
              _VideoLessonToolbarIcon(
                icon: Icons.format_italic_rounded,
                selected: selectionStyle.containsKey(quill.Attribute.italic.key),
                onTap: () => _toggleNoteInlineAttribute(
                  controller: controller,
                  focusNode: focusNode,
                  attribute: quill.Attribute.italic,
                ),
              ),
              12.horizontalSpace,
              _VideoLessonToolbarChip(
                iconAsset: _videoLessonTextSymbolIconAsset,
                selected: activeListType == null,
                onTap: () => _clearNoteListAttribute(
                  controller: controller,
                  focusNode: focusNode,
                ),
              ),
              8.horizontalSpace,
              _VideoLessonToolbarChip(
                iconAsset: _videoLessonBulletIconAsset,
                selected: activeListType == quill.Attribute.ul.value,
                onTap: () => _toggleNoteListAttribute(
                  controller: controller,
                  focusNode: focusNode,
                  attribute: quill.Attribute.ul,
                ),
              ),
              8.horizontalSpace,
              _VideoLessonToolbarChip(
                iconAsset: _videoLessonBulletNumberIconAsset,
                selected: activeListType == quill.Attribute.ol.value,
                onTap: () => _toggleNoteListAttribute(
                  controller: controller,
                  focusNode: focusNode,
                  attribute: quill.Attribute.ol,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoLessonToolbarIcon extends StatelessWidget {
  const _VideoLessonToolbarIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundGray,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          width: 36.r,
          height: 36.r,
          child: Icon(
            icon,
            size: 18.r,
            color: selected ? AppCustomColor.streakActive : AppCustomColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VideoLessonToolbarChip extends StatelessWidget {
  const _VideoLessonToolbarChip({
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          width: 44.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: selected ? AppCustomColor.backgroundBrandSoft : Colors.transparent,
            border: Border.all(
              color: selected ? AppCustomColor.borderBrand : AppCustomColor.borderDefault,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 18.r,
              height: 18.r,
              colorFilter: ColorFilter.mode(
                selected ? AppCustomColor.streakActive : AppCustomColor.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _toggleNoteInlineAttribute({
  required quill.QuillController controller,
  required FocusNode focusNode,
  required quill.Attribute attribute,
}) {
  final hasAttribute = controller.getSelectionStyle().attributes.containsKey(attribute.key);
  controller.formatSelection(hasAttribute ? quill.Attribute.clone(attribute, null) : attribute);
  focusNode.requestFocus();
}

void _toggleNoteListAttribute({
  required quill.QuillController controller,
  required FocusNode focusNode,
  required quill.Attribute<String?> attribute,
}) {
  final activeListType = controller.getSelectionStyle().attributes[quill.Attribute.list.key]?.value as String?;
  controller.formatSelection(activeListType == attribute.value ? quill.Attribute.clone(quill.Attribute.list, null) : attribute);
  focusNode.requestFocus();
}

void _clearNoteListAttribute({
  required quill.QuillController controller,
  required FocusNode focusNode,
}) {
  controller.formatSelection(quill.Attribute.clone(quill.Attribute.list, null));
  focusNode.requestFocus();
}
