part of '../../habit.dart';

/// Re-anchor screen (Figma `reAnchor`, PRD §9.1): before a course's first
/// lesson, the user picks one BTV-authored reason "why this matters to them"
/// (single-choice) to build motivation, then "Start Learning" proceeds into
/// the lesson. Pops `true` when the user starts; `null` if they back out.
class ReanchorPage extends StatefulWidget {
  final List<ReanchorReasonEntity> reasons;

  const ReanchorPage({super.key, required this.reasons});

  static Future<bool?> push(BuildContext context, {required List<ReanchorReasonEntity> reasons}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReanchorPage(reasons: reasons)),
    );
  }

  @override
  State<ReanchorPage> createState() => _ReanchorPageState();
}

class _ReanchorPageState extends State<ReanchorPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      body: SafeBody(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              AppText(
                context.l10n.habit.adoptHeaderLabel,
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.brandPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              12.verticalSpace,
              AppText(
                context.l10n.habit.reanchorTitle,
                textAlign: TextAlign.center,
                style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
              ),
              32.verticalSpace,
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10.w,
                runSpacing: 10.h,
                children: widget.reasons.map((r) {
                  final selected = _selectedId == r.id;
                  return Semantics(
                    button: true,
                    selected: selected,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(1000.r),
                      onTap: () => setState(() => _selectedId = r.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selected ? AppCustomColor.brandPrimary : AppCustomColor.backgroundWhite,
                          borderRadius: BorderRadius.circular(1000.r),
                          border: Border.all(
                            color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                          ),
                        ),
                        child: AppText(
                          r.reason.text,
                          style: AppStyle.text14.copyWith(
                            color: selected ? AppCustomColor.textWhite : AppCustomColor.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              DButton(
                text: context.l10n.habit.reanchorStartButton,
                onPressed: _selectedId == null ? null : () => Navigator.of(context).pop(true),
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
