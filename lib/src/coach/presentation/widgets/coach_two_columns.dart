part of '../../coach.dart';

/// Nhịp 3 — the two-column draft, as drawn (design `14 · AI Coach`, twoCols).
///
/// A white card in the thread: two columns side by side, "CHUYỆN ĐÃ XẢY RA"
/// muted on the left, "VẤN ĐỀ THẬT CỦA TÔI" in the accent on the right, and one
/// hint line under them. Every line on the left came out of the reader's own
/// telling; the server drops anything the model lifted from its own questions
/// before this ever renders.
///
/// A tap moves a line across — that is the whole visible interaction, exactly
/// as the design draws it (no icons on a line). The flow doc also lets the
/// reader "sửa chữ", so a long-press opens the line in place for editing;
/// emptying it deletes it. Nothing visible is added for that: a garbled line
/// is a rare case and the drawing stays clean for the common one.
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
    final l10n = context.l10n.coach;

    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: CoachStyle.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: CoachStyle.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Column(
                  title: l10n.twoColsLeftTitle,
                  titleColor: CoachStyle.textMuted,
                  lines: left,
                  inRight: false,
                  onMove: onMove,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: _Column(
                  title: l10n.twoColsRightTitle,
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
          SizedBox(height: 11.h),
          Text(
            l10n.twoColsHint,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: CoachStyle.textMuted,
            ),
          ),
        ],
      ),
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

/// One drafted line. Tap moves it across; long-press edits it in place.
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
  late final TextEditingController _controller = TextEditingController(text: widget.text);
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final value = _controller.text.trim();
    setState(() => _editing = false);
    // An emptied line is a deleted line.
    if (value.isEmpty) {
      widget.onDelete();

      return;
    }
    if (value != widget.text) widget.onEdit(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final background = widget.highlighted ? CoachStyle.selectedBackground : CoachStyle.chipBackground;
    final borderColor = widget.highlighted ? CoachStyle.selectedBorderSoft : CoachStyle.border;
    final textColor = widget.highlighted ? CoachStyle.selectedText : CoachStyle.textBody;
    final style = TextStyle(
      fontSize: 12.sp,
      fontWeight: widget.highlighted ? FontWeight.w700 : FontWeight.w600,
      height: 1.4,
      color: textColor,
    );

    return Semantics(
      button: !_editing,
      label: _editing ? null : l10n.lineMoveSemantics,
      child: GestureDetector(
        onTap: _editing ? null : widget.onMove,
        onLongPress: _editing ? null : () => setState(() => _editing = true),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: _editing
              ? TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commit(),
                  onTapOutside: (_) => _commit(),
                  style: style,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.lineEditHint,
                    hintStyle: style.copyWith(color: CoachStyle.textMuted),
                  ),
                )
              : Text(widget.text, style: style),
        ),
      ),
    );
  }
}
