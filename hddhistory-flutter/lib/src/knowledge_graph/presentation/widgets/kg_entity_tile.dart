part of '../../knowledge_graph.dart';

/// Một thực thể trong danh sách: huy hiệu loại, tên, mô tả một dòng.
///
/// [trailing] để chỗ cho thông tin riêng của từng danh sách — số bước trên đồ
/// thị ở màn hồ sơ, không có gì ở màn tìm kiếm.
class KgEntityTile extends StatelessWidget {
  const KgEntityTile({
    super.key,
    required this.type,
    required this.name,
    this.description,
    this.trailing,
    this.onTap,
  });

  final KgEntityType type;
  final String name;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final desc = description?.trim() ?? '';

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: kgEntityTypeColor(type).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                kgEntityTypeIcon(type),
                size: 20.w,
                color: kgEntityTypeColor(type),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    maxLines: 2,
                    style: AppStyle.textBold14.copyWith(
                      color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    AppText(
                      desc,
                      maxLines: 2,
                      style: AppStyle.text12.copyWith(
                        color: studyThemeOnBg(
                          context,
                          AppCustomColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Huy hiệu "n bước" trên danh sách thực thể liên quan.
class KgHopsBadge extends StatelessWidget {
  const KgHopsBadge({super.key, required this.hops});

  final int hops;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: AppText(
        context.l10n.knowledgeGraph.hopsBadge(count: hops),
        style: AppStyle.textBold10.copyWith(
          color: AppCustomColor.brandPrimary700,
        ),
      ),
    );
  }
}
