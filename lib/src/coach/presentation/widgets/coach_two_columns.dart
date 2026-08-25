part of '../../coach.dart';

/// ⑦ — the two-column draft.
///
/// Every line on the left came out of the reader's own telling; the server
/// throws away anything the model invented before this ever renders. The
/// sentence they write underneath is the only thing stored — which is the whole
/// reason the lines have to be theirs.
///
/// Three things can be done to a line, and the flow diagram names all three:
/// move it across, fix its wording, or delete it outright. Only the first
/// shipped at all, which left a reader looking at a line the model had garbled
/// with no way to correct it — in an exercise whose entire premise is that the
/// words are theirs.
///
/// The right column is tinted and its heading takes the accent colour: it is
/// the destination, and the design makes that legible before anyone reads a
/// word of the labels.
class CoachTwoColumns extends StatelessWidget {
  final List<String> left;
  final List<String> right;
  final void Function(int index, {required bool fromRight}) onMove;
  final void Function(int index, {required bool inRight, required String text}) onEdit;
  final void Function(int index, {required bool inRight}) onDelete;

  const CoachTwoColumns({
    super.key,
    required this.left,
    required this.right,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Column(
                  title: context.l10n.coach.twoColsLeftTitle,
                  titleColor: CoachStyle.textMuted,
                  lines: left,
                  inRight: false,
                  onMove: onMove,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _Column(
                  title: context.l10n.coach.twoColsRightTitle,
                  titleColor: CoachStyle.skin,
                  lines: right,
                  inRight: true,
                  onMove: onMove,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 11.h),
        Text(
          context.l10n.coach.twoColsHint,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: CoachStyle.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<String> lines;
  final bool inRight;
  final void Function(int index, {required bool fromRight}) onMove;
  final void Function(int index, {required bool inRight, required String text}) onEdit;
  final void Function(int index, {required bool inRight}) onDelete;

  const _Column({
    required this.title,
    required this.titleColor,
    required this.lines,
    required this.inRight,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: CoachStyle.sectionLabel(color: titleColor, size: 10.5),
        ),
        SizedBox(height: 6.h),
        if (lines.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              context.l10n.coach.twoColsEmpty,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: CoachStyle.textMuted,
              ),
            ),
          )
        else
          // Keyed by position AND text: a line that is edited must rebuild its
          // controller, and a line that is deleted must not hand its half-typed
          // state to whichever line slides up into its index.
          ...lines.indexed.map(
            (entry) => Padding(
              key: ValueKey('${inRight}_${entry.$1}_${entry.$2}'),
              padding: EdgeInsets.only(bottom: 6.h),
              child: _DraftLine(
                text: entry.$2,
                highlighted: inRight,
                onMove: () => onMove(entry.$1, fromRight: inRight),
                onEdit: (value) => onEdit(entry.$1, inRight: inRight, text: value),
                onDelete: () => onDelete(entry.$1, inRight: inRight),
              ),
            ),
          ),
      ],
    );
  }
}

/// One drafted line: tap the words to move it, the pencil to fix it, the cross
/// to drop it.
///
/// Editing happens in place rather than in a dialog. A modal over a sheet over
/// a conversation is three layers deep for changing four words, and the reader
/// is mid-exercise — they should not lose sight of the other column while doing
/// it.
class _DraftLine extends StatefulWidget {
  final String text;
  final bool highlighted;
  final VoidCallback onMove;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  const _DraftLine({
    required this.text,
    required this.highlighted,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DraftLine> createState() => _DraftLineState();
}

class _DraftLineState extends State<_DraftLine> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final value = _controller.text.trim();
    setState(() => _editing = false);
    // An emptied line is a deleted line. Asking someone to clear a field and
    // then also press the cross is a step that exists only for the code's sake.
    if (value.isEmpty) {
      widget.onDelete();

      return;
    }
    if (value != widget.text) widget.onEdit(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final background =
        widget.highlighted ? CoachStyle.selectedBackground : CoachStyle.chipBackground;
    final borderColor =
        widget.highlighted ? CoachStyle.selectedBorderSoft : CoachStyle.border;
    final textColor =
        widget.highlighted ? CoachStyle.selectedText : CoachStyle.textBody;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: _editing ? _editor(l10n, textColor) : _row(l10n, textColor),
    );
  }

  Widget _row(dynamic l10n, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: widget.onMove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: widget.highlighted ? FontWeight.w700 : FontWeight.w600,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        _IconTap(
          icon: Icons.edit_outlined,
          semantic: l10n.lineEdit,
          onTap: () => setState(() => _editing = true),
        ),
        _IconTap(
          icon: Icons.close_rounded,
          semantic: l10n.lineDelete,
          onTap: widget.onDelete,
        ),
      ],
    );
  }

  Widget _editor(dynamic l10n, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _commit(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: textColor,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        _IconTap(
          icon: Icons.check_rounded,
          semantic: l10n.lineSave,
          onTap: _commit,
        ),
      ],
    );
  }
}

class _IconTap extends StatelessWidget {
  final IconData icon;
  final String semantic;
  final VoidCallback onTap;

  const _IconTap({
    required this.icon,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // The icon is 15px but the target is not: a 15px tap target on a line
        // somebody is trying to correct is a line they cannot correct.
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 4.h),
          child: Icon(icon, size: 15.sp, color: CoachStyle.textMuted),
        ),
      ),
    );
  }
}
