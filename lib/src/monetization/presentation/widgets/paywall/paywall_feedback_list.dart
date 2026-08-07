part of '../../../monetization.dart';

class FeedbackContent {
  final String userName;
  final String title;
  final String description;
  final int stars;
  final String avatarUrl;

  const FeedbackContent({
    required this.userName,
    required this.title,
    required this.description,
    required this.stars,
    this.avatarUrl = '',
  });
}

class PaywallFeedbackList extends StatelessWidget {
  final VoidCallback? onFirstScroll;

  const PaywallFeedbackList({
    super.key,
    this.onFirstScroll,
  });

  /// Remote cards from the paywall config win; the bundled three are the
  /// floor so the carousel never renders empty on old configs.
  List<FeedbackContent> _resolveFeedbacks(BuildContext context) {
    final remote = context.read<IapCubit>().resolvedPaywallConfig.reviews;
    if (remote.isNotEmpty) {
      return [
        for (final review in remote)
          FeedbackContent(
            userName: review.name,
            title: review.title.text,
            description: review.body.text,
            stars: review.rating,
            avatarUrl: review.avatarUrl,
          ),
      ];
    }

    final monetizationTexts = l10n.monetization;

    return [
      FeedbackContent(
        userName: 'Bete Noir',
        title: monetizationTexts.review1Title,
        description: monetizationTexts.review1Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Monilosa',
        title: monetizationTexts.review2Title,
        description: monetizationTexts.review2Body,
        stars: 5,
      ),
      FeedbackContent(
        userName: 'Julie666',
        title: monetizationTexts.review3Title,
        description: monetizationTexts.review3Body,
        stars: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final feedbacks = _resolveFeedbacks(context);
    if (feedbacks.isEmpty) return const SizedBox.shrink();

    bool hasTriggeredScroll = false;

    return SizedBox(
      height: 195.h,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (hasTriggeredScroll || notification.metrics.axis != Axis.horizontal || notification.metrics.pixels <= 0) {
            return false;
          }
          hasTriggeredScroll = true;
          onFirstScroll?.call();
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          itemCount: feedbacks.length,
          separatorBuilder: (_, _) => 16.horizontalSpace,
          itemBuilder: (context, index) => _FeedbackCard(feedback: feedbacks[index]),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackContent feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 305.w,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppCustomColor.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ReviewerAvatar(name: feedback.userName, avatarUrl: feedback.avatarUrl),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      feedback.userName,
                      maxLines: 1,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.textTertiary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    2.verticalSpace,
                    _StarRow(stars: feedback.stars),
                  ],
                ),
              ),
            ],
          ),
          12.verticalSpace,
          AppText(
            feedback.title,
            maxLines: 2,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.75,
            ),
          ),
          8.verticalSpace,
          Expanded(
            child: AppText(
              feedback.description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textSecondary,
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;

  const _StarRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3.w),
          child: FaIcon(
            FontAwesomeIcons.solidStar,
            size: 12.w,
            color: isFilled ? const Color(0xFF4B44CA) : AppCustomColor.feedbackStarInactive,
          ),
        );
      }),
    );
  }
}

/// The reviewer's avatar. A remote image when the config supplies one, else an
/// initial-letter disc — the bundled reviews ship no artwork, and a broken URL
/// downgrades to the same disc instead of a gray error box.
class _ReviewerAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _ReviewerAvatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final size = 36.w;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEDEAFD),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppText(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: AppStyle.text14.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4B44CA),
          ),
        ),
      ),
    );

    if (avatarUrl.isEmpty) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
