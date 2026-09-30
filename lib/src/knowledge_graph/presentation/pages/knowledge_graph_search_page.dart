part of '../../knowledge_graph.dart';

/// Tra cứu đồ thị tri thức: gõ tên một nhân vật, sự kiện, triều đại hay địa
/// danh để mở hồ sơ của nó.
///
/// Mở ra là đã có danh sách sẵn (server trả về danh sách đầu khi `q` rỗng) chứ
/// không phải một ô trống — người học thường chưa biết trong đồ thị có những gì
/// để mà gõ.
class KnowledgeGraphSearchPage extends StatefulWidget {
  const KnowledgeGraphSearchPage({super.key});

  @override
  State<KnowledgeGraphSearchPage> createState() =>
      _KnowledgeGraphSearchPageState();
}

class _KnowledgeGraphSearchPageState extends State<KnowledgeGraphSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<KnowledgeGraphCubit>().ensureEntitiesLoaded());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openEntity(String id) {
    AppHaptic.select();
    KnowledgeGraphEntityRoute(id).push(context);
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
          child: Column(
            children: [
              _KgHeader(title: l10n.searchTitle),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: _KgSearchField(
                  controller: _controller,
                  hint: l10n.searchHint,
                ),
              ),
              Expanded(
                child: BlocBuilder<KnowledgeGraphCubit, KnowledgeGraphState>(
                  builder: (context, state) {
                    // Chỉ che màn hình bằng vòng xoay ở lần nạp ĐẦU. Những lần
                    // gõ sau giữ nguyên kết quả cũ dưới tay, nếu không thì danh
                    // sách sẽ nhấp nháy theo từng chữ người dùng gõ.
                    if (state.isSearching && state.results.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.searchStatus == KgStatus.failure &&
                        state.results.isEmpty) {
                      return _KgMessage(
                        icon: Icons.wifi_off_rounded,
                        title: l10n.errorTitle,
                        message: state.searchError.isEmpty
                            ? l10n.errorBody
                            : state.searchError,
                        actionLabel: l10n.retry,
                        onAction: () => unawaited(
                          context.read<KnowledgeGraphCubit>().submitQuery(),
                        ),
                      );
                    }

                    if (state.hasNoResult) {
                      return _KgMessage(
                        icon: Icons.search_off_rounded,
                        title: l10n.emptyTitle,
                        message: l10n.emptyBody,
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: floatingNavBarHeight(context) + 24.h,
                      ),
                      itemCount: state.results.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 66.w,
                        color: AppCustomColor.borderDefault.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final entity = state.results[index];
                        return KgEntityTile(
                          type: entity.type,
                          name: entity.name,
                          description: entity.description,
                          onTap: () => _openEntity(entity.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KgSearchField extends StatelessWidget {
  const _KgSearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KnowledgeGraphCubit>();

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: cubit.onQueryChanged,
      onSubmitted: (_) => unawaited(cubit.submitQuery()),
      style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20.w,
          color: AppCustomColor.textTertiary,
        ),
        suffixIcon: BlocBuilder<KnowledgeGraphCubit, KnowledgeGraphState>(
          buildWhen: (p, c) => p.query.isEmpty != c.query.isEmpty,
          builder: (context, state) {
            if (state.query.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18.w,
                color: AppCustomColor.textTertiary,
              ),
              onPressed: () {
                controller.clear();
                unawaited(cubit.clearQuery());
              },
            );
          },
        ),
        filled: true,
        fillColor: AppCustomColor.backgroundGray,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Đầu trang có nút quay lại — cùng dạng với các màn hình được push khác.
class _KgHeader extends StatelessWidget {
  const _KgHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 20.w, 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.w,
              color: studyThemeOnBg(context, AppCustomColor.textPrimary),
            ),
          ),
          Expanded(
            child: AppText(
              title,
              style: AppStyle.textBold16.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái rỗng / lỗi dùng chung cho cả hai màn hình của tính năng.
class _KgMessage extends StatelessWidget {
  const _KgMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.w, color: AppCustomColor.textTertiary),
            SizedBox(height: 12.h),
            AppText(
              title,
              textAlign: TextAlign.center,
              style: AppStyle.textBold14.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textPrimary),
              ),
            ),
            SizedBox(height: 6.h),
            AppText(
              message,
              textAlign: TextAlign.center,
              // Không cắt bớt: mặc định của AppText là 10 dòng kèm ellipsis,
              // mà đây là chỗ duy nhất giải thích cho người dùng chuyện gì đang
              // xảy ra.
              maxLines: 100,
              style: AppStyle.text12.copyWith(
                color: studyThemeOnBg(context, AppCustomColor.textSecondary),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: onAction,
                child: AppText(
                  actionLabel!,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.brandPrimary700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
