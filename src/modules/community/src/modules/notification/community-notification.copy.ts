import { CommunityNotificationType } from '../../enum/community.enum';

export interface ICommunityPushCopy {
  title: string;
  body: string;
}

/**
 * Push copy for community events, spelled locale by locale.
 *
 * Kept in code rather than in `src/base/i18n` (which only ships en and vi) or in
 * the admin notification templates (which are scheduled campaigns, not
 * event-driven sends). `{name}` is the person who acted; `{reason}` is the
 * moderator's note.
 */
const COPY: Record<
  CommunityNotificationType,
  Record<string, ICommunityPushCopy>
> = {
  [CommunityNotificationType.COMMENT_ON_POST]: {
    vi: { title: 'Bình luận mới', body: '{name} đã bình luận bài của bạn' },
    en: { title: 'New comment', body: '{name} commented on your post' },
    zh: { title: '新评论', body: '{name} 评论了你的帖子' },
    ja: { title: '新しいコメント', body: '{name} さんがあなたの投稿にコメントしました' },
    ko: { title: '새 댓글', body: '{name}님이 회원님의 글에 댓글을 남겼습니다' },
  },
  [CommunityNotificationType.REPLY_TO_COMMENT]: {
    vi: { title: 'Trả lời mới', body: '{name} đã trả lời bình luận của bạn' },
    en: { title: 'New reply', body: '{name} replied to your comment' },
    zh: { title: '新回复', body: '{name} 回复了你的评论' },
    ja: { title: '新しい返信', body: '{name} さんがあなたのコメントに返信しました' },
    ko: { title: '새 답글', body: '{name}님이 회원님의 댓글에 답글을 남겼습니다' },
  },
  [CommunityNotificationType.COMMENT_ON_FOLLOWED_POST]: {
    vi: {
      title: 'Bàn luận mới',
      body: '{name} đã bình luận trong bài bạn theo dõi',
    },
    en: {
      title: 'New comment',
      body: '{name} commented on a post you follow',
    },
    zh: { title: '新评论', body: '{name} 在你关注的帖子中发表了评论' },
    ja: {
      title: '新しいコメント',
      body: 'フォロー中の投稿に {name} さんがコメントしました',
    },
    ko: {
      title: '새 댓글',
      body: '{name}님이 회원님이 팔로우한 글에 댓글을 남겼습니다',
    },
  },
  // Pushed once per BATCH, not per like: the first like, then the first one
  // after the author has read the last lot — see `notifyLike`.
  [CommunityNotificationType.LIKE_ON_POST]: {
    vi: { title: 'Bài của bạn được thích', body: '{name} đã thích bài viết của bạn' },
    en: { title: 'Someone liked your post', body: '{name} liked your post' },
    zh: { title: '有人喜欢你的帖子', body: '{name} 喜欢了你的帖子' },
    ja: {
      title: 'あなたの投稿にいいねがつきました',
      body: '{name} さんがあなたの投稿にいいねしました',
    },
    ko: {
      title: '회원님의 글을 좋아합니다',
      body: '{name}님이 회원님의 글을 좋아합니다',
    },
  },
  [CommunityNotificationType.ANSWER_ON_WEEKLY]: {
    vi: {
      title: 'Câu hỏi của tuần',
      body: '{name} vừa trả lời câu hỏi bạn đã trả lời',
    },
    en: {
      title: 'Question of the week',
      body: '{name} just answered the question you answered',
    },
    zh: { title: '本周问题', body: '{name} 刚刚回答了你回答过的问题' },
    ja: {
      title: '今週の質問',
      body: 'あなたが答えた質問に {name} さんが回答しました',
    },
    ko: {
      title: '이주의 질문',
      body: '회원님이 답한 질문에 {name}님이 답했습니다',
    },
  },
  // `{room}` is the room's own title ("Câu hỏi của tuần"), so the push says
  // WHERE the answer landed — "someone replied" with no place attached is a
  // notification the reader cannot act on without opening the app to find out.
  [CommunityNotificationType.MESSAGE_IN_ROOM]: {
    vi: { title: '{room}', body: '{name} vừa trả lời trong bàn luận' },
    en: { title: '{room}', body: '{name} just answered in the discussion' },
    zh: { title: '{room}', body: '{name} 刚刚在讨论中回复了' },
    ja: { title: '{room}', body: '{name} さんが討論に回答しました' },
    ko: { title: '{room}', body: '{name}님이 토론에 답했습니다' },
  },
  [CommunityNotificationType.OFFICIAL_REPLY]: {
    vi: { title: 'Đội ngũ HDDhistory đã trả lời', body: 'Có phản hồi trong bài của bạn' },
    en: { title: 'The HDDhistory team replied', body: 'There is a reply on your post' },
    zh: { title: 'HDDhistory 团队已回复', body: '你的帖子有新回复' },
    ja: { title: 'HDDhistory チームが返信しました', body: 'あなたの投稿に返信があります' },
    ko: { title: 'HDDhistory 팀이 답변했습니다', body: '회원님의 글에 답변이 있습니다' },
  },
  [CommunityNotificationType.POST_HIDDEN]: {
    vi: { title: 'Bài của bạn đã được ẩn', body: '{reason}' },
    en: { title: 'Your post was hidden', body: '{reason}' },
    zh: { title: '你的帖子已被隐藏', body: '{reason}' },
    ja: { title: 'あなたの投稿は非表示になりました', body: '{reason}' },
    ko: { title: '회원님의 글이 숨겨졌습니다', body: '{reason}' },
  },
  [CommunityNotificationType.SANCTION_APPLIED]: {
    vi: { title: 'Bạn tạm thời không thể đăng bài', body: '{reason}' },
    en: { title: 'You cannot post for now', body: '{reason}' },
    zh: { title: '你暂时无法发帖', body: '{reason}' },
    ja: { title: '現在投稿できません', body: '{reason}' },
    ko: { title: '지금은 글을 쓸 수 없습니다', body: '{reason}' },
  },
};

const FALLBACK_LOCALE = 'en';

export function communityPushCopy(
  type: CommunityNotificationType,
  locale: string | undefined,
  variables: Record<string, string> = {},
): ICommunityPushCopy {
  const byLocale = COPY[type];
  const copy = byLocale[locale ?? FALLBACK_LOCALE] ?? byLocale[FALLBACK_LOCALE];

  const fill = (text: string) =>
    text.replace(/\{(\w+)\}/g, (match, key) => variables[key] ?? match).trim();

  return { title: fill(copy.title), body: fill(copy.body) };
}
