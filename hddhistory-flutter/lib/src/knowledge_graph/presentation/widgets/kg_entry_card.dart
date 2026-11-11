part of '../../knowledge_graph.dart';

/// Lối vào tính năng tra cứu, đặt trên tab Thư viện.
///
/// Là một thẻ chứ không phải một dòng trong danh sách: đây là thứ duy nhất
/// trên tab đó không gắn với tiến độ học của người dùng, nên nó cần tự giới
/// thiệu mình làm được gì.
class KnowledgeGraphEntryCard extends StatelessWidget {
  const KnowledgeGraphEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.knowledgeGraph;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          AppHaptic.select();
          const KnowledgeGraphSearchRoute().push(context);
        },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppCustomColor.brandPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.hub_rounded,
                  size: 21.w,
                  color: AppCustomColor.brandPrimary700,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      l10n.entryTitle,
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    AppText(
                      l10n.entrySubtitle,
                      maxLines: 2,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.w,
                color: AppCustomColor.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
