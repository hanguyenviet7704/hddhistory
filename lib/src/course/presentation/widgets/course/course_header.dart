part of '../../../course.dart';

/// Anchor for [ImportFocusGuide]'s spotlight — the guide cuts its hole around
/// whatever rect this key resolves to, so the two cannot drift apart.
final GlobalKey _importButtonKey = GlobalKey();

/// The import button's glyph, verbatim from the design (`4 · Explore` header): a
/// page with a folded corner and an arrow pointing INTO it.
///
/// Inlined rather than bundled, for the same reason Profile inlines its Library
/// icons — it matches 1:1 with no asset rebuild. It replaces
/// `Icons.file_upload_outlined`, which draws a tray with an arrow leaving it:
/// the wrong shape (no document) and the wrong direction (out, not in) for a
/// button whose job is "bring your own material in".
const String _kImportDocSvg =
    '''<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M14 3.5H7.5A2.5 2.5 0 005 6v12a2.5 2.5 0 002.5 2.5h9A2.5 2.5 0 0019 18V8.5L14 3.5z" stroke="#9AA4B2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M13.75 3.75V9h5" stroke="#9AA4B2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M12 11.5v5" stroke="#9AA4B2" stroke-width="2" stroke-linecap="round"/><path d="M9.75 14.25L12 16.5l2.25-2.25" stroke="#9AA4B2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

/// Explore's top bar: a search field, and beside it the import affordance.
class CourseHeader extends StatelessWidget {
  const CourseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<CourseCubit, CourseState>(
        buildWhen: (prev, curr) => prev.searchQuery != curr.searchQuery || prev.isSearchActive != curr.isSearchActive,
        builder: (context, state) {
          return Row(
            children: [
              Expanded(child: _SearchField(state: state)),
              // Gone while searching: the field takes the full width so a long
              // query still fits, and importing is not something anyone reaches
              // for mid-search.
              if (!state.isSearchActive) ...[
                10.horizontalSpace,
                // Gone entirely while the feature is switched off. A button that
                // opens a screen whose only message is "not right now" is worse
                // than no button: it reads as broken rather than as paused.
                BlocBuilder<LearningImportCubit, LearningImportState>(
                  bloc: AppDI.injector.get<LearningImportCubit>(),
                  buildWhen: (previous, current) => previous.quota.enabled != current.quota.enabled || previous.quota.isKnown != current.quota.isKnown,
                  builder: (context, importState) => importState.quota.isFeatureOff ? const SizedBox.shrink() : const _ImportButton(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The pill that opens the import sheet, beside the search field.
///
/// The redesign promotes "make a lesson from your own material" to a permanent
/// affordance on Explore. It was previously reachable only through a row on
/// Profile, which is where features go to be forgotten.
class _ImportButton extends StatelessWidget {
  const _ImportButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.learningImport.createButton,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          ExploreTracking.track(TrackingKey.exploreImportClick);
          const ImportLessonRoute().push(context);
        },
        child: Container(
          key: _importButtonKey,
          // Square-and-circular so it reads as a sibling of the search pill
          // rather than as an icon floating beside it.
          width: 56.h,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundGray,
            shape: BoxShape.circle,
            border: Border.all(color: AppCustomColor.borderDefault, width: 2),
          ),
          alignment: Alignment.center,
          child: SvgPicture.string(_kImportDocSvg, width: 22.w, height: 22.w),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.state});

  final CourseState state;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state.isSearchActive
          ? null
          : () {
              AppHaptic.select();
              ExploreTracking.track(TrackingKey.exploreSearchClick);
              context.read<CourseCubit>().activateSearch();
            },
      child: Container(
        height: 56.h,
        padding: EdgeInsets.only(
          left: 22.w,
          right: state.isSearchActive ? 14.w : 4.w,
          top: 4.h,
          bottom: 4.h,
        ),
        decoration: BoxDecoration(
          color: state.isSearchActive ? AppCustomColor.backgroundWhite : AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: state.isSearchActive ? AppCustomColor.brandPrimary.withValues(alpha: 0.6) : AppCustomColor.borderDefault,
            width: 2,
          ),
          boxShadow: state.isSearchActive ? [const BoxShadow(color: Color(0xFFEBF0F7), blurRadius: 2)] : null,
        ),
        child: Row(
          children: [
            Semantics(
              label: context.l10n.allcourse.searchSemanticLabel,
              child: Icon(
                Icons.search_rounded,
                color: AppCustomColor.textTertiary,
                size: 24.w,
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: state.isSearchActive
                  ? TextField(
                      autofocus: true,
                      controller: context.read<CourseCubit>().searchController,
                      style: AppStyle.text16.copyWith(
                        color: AppCustomColor.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.allcourse.searchPlaceholderActive,
                        hintStyle: AppStyle.text16.copyWith(
                          color: AppCustomColor.textTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                      // Live filtering happens via onChanged; results show
                      // as the user types. "Recent" now tracks viewed
                      // courses, so there's nothing to persist on submit.
                      onChanged: context.read<CourseCubit>().onSearchChanged,
                    )
                  : AppText(
                      context.l10n.allcourse.searchPlaceholder,
                      style: AppStyle.text16.copyWith(
                        color: AppCustomColor.textTertiary,
                      ),
                    ),
            ),
            if (state.isSearchActive)
              Semantics(
                label: context.l10n.allcourse.searchClearSemanticLabel,
                button: true,
                child: GestureDetector(
                  // Spec: "X" clears the entered text (staying in search
                  // → shows Recent); tapping it again when empty exits.
                  onTap: () {
                    AppHaptic.select();
                    final cubit = context.read<CourseCubit>();
                    if (state.searchQuery.isEmpty) {
                      cubit.deactivateSearch();
                    } else {
                      ExploreTracking.track(TrackingKey.exploreSearchClearClick);
                      cubit.clearSearchText();
                    }
                  },
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: const BoxDecoration(
                      color: AppCustomColor.neutral300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14.w,
                      color: AppCustomColor.backgroundWhite,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
