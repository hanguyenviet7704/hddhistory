part of '../../home.dart';

/// Admin-configurable promo banner (design `2 · Home`): a full-width image
/// slot between "New today" and "Jump back in". Content comes from
/// GET /home-banner — when the config is off, has no image yet, or the fetch
/// failed, the whole section INCLUDING its bottom spacing collapses to zero
/// height, so Home reads exactly as it did before the slot existed.
class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) => previous.homeBanner != current.homeBanner,
      builder: (context, state) {
        final banner = state.homeBanner;
        if (banner == null || !banner.isVisible) return const SizedBox.shrink();
        final linkUrl = banner.linkUrl;
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
          child: Semantics(
            button: linkUrl.isNotEmpty,
            image: true,
            label: context.l10n.home.homeBannerSemantic,
            child: GestureDetector(
              onTap: linkUrl.isEmpty
                  ? null
                  : () {
                      AppHaptic.select();
                      linkUrl.launchURL();
                    },
              child: SizedBox(
                width: double.infinity,
                height: 78.h,
                child: CacheNetworkGraphic(
                  url: banner.imageUrl,
                  borderRadius: BorderRadius.circular(18.r),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
