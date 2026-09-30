part of '../../knowledge_graph.dart';

/// Hồ sơ một thực thể lịch sử, dựng hoàn toàn từ đồ thị tri thức: nhân vật này
/// là ai, đã làm những gì, được nhắc tới ở đâu, cùng thời với ai, và chép từ
/// nguồn nào.
///
/// Không có màn hình nào trong app tự viết mấy đoạn này — chúng là các cạnh
/// của đồ thị được đọc ra thành câu, nên thêm một quan hệ ở server là hồ sơ
/// dày thêm mà không phải sửa app.
class KnowledgeGraphProfilePage extends StatefulWidget {
  const KnowledgeGraphProfilePage({super.key, required this.entityId});

  final String entityId;

  @override
  State<KnowledgeGraphProfilePage> createState() =>
      _KnowledgeGraphProfilePageState();
}

class _KnowledgeGraphProfilePageState extends State<KnowledgeGraphProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<KnowledgeGraphCubit>().openEntity(widget.entityId));
    });
  }

  /// Mở hồ sơ của một thực thể khác, rồi nạp lại hồ sơ của MÌNH khi quay về.
  ///
  /// Cubit là singleton dùng chung, nên sau khi trang con ghi hồ sơ của nó vào
  /// state, trang này quay lại sẽ đang cầm dữ liệu của trang con. Nạp lại là
  /// cách rẻ nhất để hai trang cùng đúng mà không phải nhân bản state theo id.
  Future<void> _openEntity(String id) async {
    if (id == widget.entityId) return;
    AppHaptic.select();
    await KnowledgeGraphEntityRoute(id).push(context);
    if (!mounted) return;
    unawaited(context.read<KnowledgeGraphCubit>().openEntity(widget.entityId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.knowledgeGraph;

    return Scaffold(
      backgroundColor: studyThemeScaffoldColor(
        context,
        AppCustomColor.backgroundWhite,
      ),
      body: ThemedBackground(
        child: SafeBody(
          child: BlocBuilder<KnowledgeGraphCubit, KnowledgeGraphState>(
            builder: (context, state) {
              final profile = state.profile;
              // Chỉ vẽ khi hồ sơ trong state ĐÚNG là thực thể của trang này —
              // xem ghi chú ở [_openEntity].
              final isMine = profile != null && profile.id == widget.entityId;

              if (state.profileStatus == KgStatus.failure) {
                return Column(
                  children: [
                    _KgHeader(title: l10n.profileTitle),
                    Expanded(
                      child: _KgMessage(
                        icon: Icons.error_outline_rounded,
                        title: l10n.errorTitle,
                        message: state.profileError.isEmpty
                            ? l10n.errorBody
                            : state.profileError,
                        actionLabel: l10n.retry,
                        onAction: () => unawaited(
                          context.read<KnowledgeGraphCubit>().openEntity(
                            widget.entityId,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!isMine) {
                return Column(
                  children: [
                    _KgHeader(title: l10n.profileTitle),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _KgHeader(title: l10n.profileTitle),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(
                        bottom: floatingNavBarHeight(context) + 24.h,
                      ),
                      children: [
                        _KgProfileHero(profile: profile),
                        if (profile.outgoing.isNotEmpty)
                          _KgRelationSection(
                            title: l10n.sectionDid,
                            relations: profile.outgoing,
                            // "lãnh đạo · Trận Bạch Đằng": chủ ngữ là nhân vật
                            // đang xem, nên nhãn quan hệ đứng trước.
                            labelFirst: true,
                            onTap: _openEntity,
                          ),
                        if (profile.incoming.isNotEmpty)
                          _KgRelationSection(
                            title: l10n.sectionMentioned,
                            relations: profile.incoming,
                            // "Dương Tam Kha · kế vị": ở đây chủ ngữ là thực
                            // thể đầu kia, nên tên đứng trước nhãn.
                            labelFirst: false,
                            onTap: _openEntity,
                          ),
                        if (state.related.isNotEmpty)
                          _KgRelatedSection(
                            title: l10n.sectionRelated,
                            related: state.related,
                            onTap: _openEntity,
                          ),
                        if (profile.samePeriod.isNotEmpty)
                          _KgSamePeriodSection(
                            title: l10n.sectionSamePeriod,
                            entities: profile.samePeriod,
                            onTap: _openEntity,
                          ),
                        if (profile.sources.isNotEmpty)
                          _KgSourcesSection(
                            title: l10n.sectionSources,
                            sources: profile.sources,
                          ),
                      ],
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

class _KgProfileHero extends StatelessWidget {
  const _KgProfileHero({required this.profile});

  final KgEntityProfile profile;

  @override
  Widget build(BuildContext context) {
    final description = profile.description?.trim() ?? '';
    final note = profile.note?.trim() ?? '';
    final period = profile.period;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: kgEntityTypeColor(
                    profile.type,
                  ).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  kgEntityTypeIcon(profile.type),
                  size: 28.w,
                  color: kgEntityTypeColor(profile.type),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      profile.name,
                      maxLines: 100,
                      style: AppStyle.textBold20.copyWith(
                        color: studyThemeOnBg(
                          context,
                          AppCustomColor.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        _KgChip(
                          label: kgEntityTypeLabel(context, profile.type),
                          color: kgEntityTypeColor(profile.type),
                        ),
                        if (period != null)
                          _KgChip(
                            label: kgPeriodRange(period).isEmpty
                                ? period.name
                                : '${period.name} · ${kgPeriodRange(period)}',
                            color: AppCustomColor.textSecondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 14.h),
            AppText(
              description,
              // Mô tả là nội dung chính của màn hình này; mặc định 10 dòng của
              // AppText sẽ cắt mất đoạn dài.
              maxLines: 100,
              style: AppStyle.text14.copyWith(
                height: 1.5,
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppText(
                note,
                maxLines: 100,
                style: AppStyle.text12.copyWith(
                  height: 1.5,
                  color: studyThemeOnBg(context, AppCustomColor.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KgChip extends StatelessWidget {
  const _KgChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: AppText(
        label,
        style: AppStyle.textBold10.copyWith(color: color),
      ),
    );
  }
}

class _KgSectionTitle extends StatelessWidget {
  const _KgSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
      child: AppText(
        title,
        style: AppStyle.textBold14.copyWith(
          color: studyThemeOnBg(context, AppCustomColor.textPrimary),
        ),
      ),
    );
  }
}

class _KgRelationSection extends StatelessWidget {
  const _KgRelationSection({
    required this.title,
    required this.relations,
    required this.labelFirst,
    required this.onTap,
  });

  final String title;
  final List<KgRelation> relations;
  final bool labelFirst;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KgSectionTitle(title),
        ...relations.map(
          (relation) => KgEntityTile(
            type: relation.entity.type,
            name: labelFirst
                ? '${kgRelationLabel(relation.relation)} · ${relation.entity.name}'
                : '${relation.entity.name} · ${kgRelationLabel(relation.relation)}',
            description: relation.entity.description,
            onTap: () => onTap(relation.entity.id),
          ),
        ),
      ],
    );
  }
}

class _KgRelatedSection extends StatelessWidget {
  const _KgRelatedSection({
    required this.title,
    required this.related,
    required this.onTap,
  });

  final String title;
  final List<KgRelatedEntity> related;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KgSectionTitle(title),
        ...related.map(
          (entity) => KgEntityTile(
            type: entity.type,
            name: entity.name,
            // Đường đi trên đồ thị thay cho mô tả: nó trả lời đúng câu hỏi
            // "sao cái này lại liên quan?", thứ mà mô tả không nói được.
            description: entity.via.isEmpty
                ? entity.description
                : entity.via.map(kgRelationLabel).join(' → '),
            trailing: KgHopsBadge(hops: entity.hops),
            onTap: () => onTap(entity.id),
          ),
        ),
      ],
    );
  }
}

class _KgSamePeriodSection extends StatelessWidget {
  const _KgSamePeriodSection({
    required this.title,
    required this.entities,
    required this.onTap,
  });

  final String title;
  final List<KgEntitySummary> entities;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KgSectionTitle(title),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: entities
                .map(
                  (entity) => InkWell(
                    borderRadius: BorderRadius.circular(999.r),
                    onTap: () => onTap(entity.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundGray,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            kgEntityTypeIcon(entity.type),
                            size: 13.w,
                            color: kgEntityTypeColor(entity.type),
                          ),
                          SizedBox(width: 5.w),
                          AppText(
                            entity.name,
                            style: AppStyle.text12.copyWith(
                              color: AppCustomColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _KgSourcesSection extends StatelessWidget {
  const _KgSourcesSection({required this.title, required this.sources});

  final String title;
  final List<KgSource> sources;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KgSectionTitle(title),
        ...sources.map(
          (source) => Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 14.w,
                  color: AppCustomColor.textTertiary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppText(
                    source.note == null || source.note!.trim().isEmpty
                        ? source.title
                        : '${source.title} — ${source.note}',
                    maxLines: 100,
                    style: AppStyle.text12.copyWith(
                      color: studyThemeOnBg(
                        context,
                        AppCustomColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
