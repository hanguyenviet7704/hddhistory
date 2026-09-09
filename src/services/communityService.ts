import {
  CommunityContentStatus,
  CommunityPostType,
  CommunityReportStatus,
  CommunityRoomSuggestionStatus,
  CommunityTargetType,
  ICommunityAdminChatMessage,
  ICommunityChatRoom,
  ICommunityOfficialProfile,
  ICommunityAdminComment,
  ICommunityAdminPost,
  ICommunityChatQuery,
  ICommunityOfficialPostPayload,
  ICommunityReport,
  ICommunityRoomSuggestion,
  ICommunitySanction,
  ICommunityTopic,
  ICommunityTopicPayload,
  ICommunityWeeklyPayload,
  IPagedResponse,
} from "../types/interface/community.interface";
import axiosClient from "./axiosClient";

export interface CommunityPostQuery {
  page?: number;
  take?: number;
  search?: string;
  status?: CommunityContentStatus;
  type?: CommunityPostType;
  topicId?: string;
  locale?: string;
  authorId?: string;
}

export interface CommunityCommentQuery {
  page?: number;
  take?: number;
  search?: string;
  status?: CommunityContentStatus;
  postId?: string;
  authorId?: string;
}

export interface CommunityRoomSuggestionQuery {
  page?: number;
  take?: number;
  search?: string;
  status?: CommunityRoomSuggestionStatus;
  locale?: string;
}

export interface CommunityReportQuery {
  page?: number;
  take?: number;
  status?: CommunityReportStatus;
  targetType?: CommunityTargetType;
}

/**
 * Community moderation endpoints.
 *
 * All of these are the `/community/admin/*` routes, which are role-guarded and
 * — unlike the reader-facing ones — return hidden and deleted content. That is
 * the point: a moderator has to see what was reported after it came down.
 */
export const communityService = {
  // ------------------------------------------------------------------ topics
  async getTopics(params: {
    page?: number;
    take?: number;
    search?: string;
    isActive?: boolean;
  }) {
    const res = await axiosClient.get("/community/admin/topics", { params });
    return res.data?.data as IPagedResponse<ICommunityTopic>;
  },

  async createTopic(payload: ICommunityTopicPayload) {
    const res = await axiosClient.post("/community/admin/topics", payload);
    return res.data?.data as ICommunityTopic;
  },

  async updateTopic(id: string, payload: Partial<ICommunityTopicPayload>) {
    const res = await axiosClient.patch(
      `/community/admin/topics/${id}`,
      payload
    );
    return res.data?.data as ICommunityTopic;
  },

  /**
   * Deactivates the topic — it is never hard-deleted.
   *
   * Posts keep a topicId, so removing the row would leave every post in it
   * rendering a chip with no label.
   */
  async deactivateTopic(id: string) {
    const res = await axiosClient.delete(`/community/admin/topics/${id}`);
    return res.data?.data as ICommunityTopic;
  },

  // ------------------------------------------------------------------- posts
  async getPosts(params: CommunityPostQuery) {
    const res = await axiosClient.get("/community/admin/posts", { params });
    return res.data?.data as IPagedResponse<ICommunityAdminPost>;
  },

  /**
   * Hide / restore / pin / lock comments on one post.
   *
   * Hiding also hides the post's whole comment thread, closes every pending
   * report on it, and notifies the author with `hiddenReason` — so always pass
   * a reason worth showing a person.
   */
  async moderatePost(
    id: string,
    payload: {
      status?: CommunityContentStatus;
      hiddenReason?: string;
      isPinned?: boolean;
      commentsLocked?: boolean;
      /** Sửa nội dung tại chỗ. Omit để giữ nguyên; chuỗi/mảng rỗng ghi đè thật. */
      subject?: string;
      body?: string;
      images?: string[];
    }
  ) {
    const res = await axiosClient.patch(
      `/community/admin/posts/${id}`,
      payload
    );
    return res.data?.data;
  },

  /** Posts as "Đội ngũ MeUp" — one locale's feed at a time. */
  async createOfficialPost(payload: ICommunityOfficialPostPayload) {
    const res = await axiosClient.post(
      "/community/admin/posts/official",
      payload
    );
    return res.data?.data;
  },

  // ---------------------------------------------------------------- comments
  async getComments(params: CommunityCommentQuery) {
    const res = await axiosClient.get("/community/admin/comments", { params });
    return res.data?.data as IPagedResponse<ICommunityAdminComment>;
  },

  /**
   * Answers a thread as Đội ngũ MeUp.
   *
   * `parentId` replies inside a thread; leaving it off comments on the post.
   */
  async createOfficialComment(
    postId: string,
    payload: { body: string; parentId?: string }
  ) {
    const res = await axiosClient.post(
      `/community/admin/posts/${postId}/comments`,
      payload
    );
    return res.data?.data as IPagedResponse<ICommunityAdminComment>;
  },

  async moderateComment(
    id: string,
    payload: { status?: CommunityContentStatus; hiddenReason?: string }
  ) {
    const res = await axiosClient.patch(
      `/community/admin/comments/${id}`,
      payload
    );
    return res.data?.data;
  },

  // -------------------------------------------------------------- group chat
  // --------------------------------------------------- official (team) profile
  async getOfficialProfile() {
    const res = await axiosClient.get("/community/admin/official-profile");
    return (res.data?.data ?? { name: "", avatar: "" }) as ICommunityOfficialProfile;
  },

  async saveOfficialProfile(payload: ICommunityOfficialProfile) {
    const res = await axiosClient.put(
      "/community/admin/official-profile",
      payload
    );
    return res.data?.data as ICommunityOfficialProfile;
  },

  async getChatRooms() {
    const res = await axiosClient.get("/community/admin/chat/rooms");
    return (res.data?.data ?? []) as ICommunityChatRoom[];
  },

  /**
   * Creates the room, or edits the one already on that slug.
   *
   * The only way to open a room outside a script with direct database access —
   * the app opens `hoi-ban-tron` by name, so an environment without that row is
   * a 404 behind the chat button.
   */
  async upsertChatRoom(payload: {
    slug: string;
    name: string;
    isOfficial?: boolean;
    status?: CommunityContentStatus;
  }) {
    const res = await axiosClient.post("/community/admin/chat/rooms", payload);
    return res.data?.data as ICommunityChatRoom;
  },

  /**
   * Says something in a room AS the team.
   *
   * The panel could moderate a round table but never speak in one, so an
   * admin answering a member had to do it from their own phone under their own
   * name. This writes with the OFFICIAL author type, which is what makes the
   * app draw the team badge on the bubble.
   */
  async sendChatMessage(room: string, body: string) {
    const res = await axiosClient.post(
      `/community/admin/chat/rooms/${room}/messages`,
      { body }
    );
    return res.data?.data;
  },

  async getChatMessages(params: ICommunityChatQuery) {
    const res = await axiosClient.get("/community/admin/chat/messages", {
      params,
    });
    return res.data?.data as IPagedResponse<ICommunityAdminChatMessage>;
  },

  async moderateChatMessage(
    id: string,
    payload: { status?: CommunityContentStatus; hiddenReason?: string }
  ) {
    const res = await axiosClient.patch(
      `/community/admin/chat/messages/${id}`,
      payload
    );
    return res.data?.data;
  },

  // ----------------------------------------------------------------- reports
  async getReports(params: CommunityReportQuery) {
    const res = await axiosClient.get("/community/admin/reports", { params });
    return res.data?.data as IPagedResponse<ICommunityReport>;
  },

  /**
   * Close a report.
   *
   * RESOLVED_HIDDEN takes the content down as well (and notifies its author);
   * RESOLVED_KEPT leaves it up. Either way every other pending report on the
   * same item is closed with the same verdict, so the queue does not keep
   * offering work that is already done.
   */
  async resolveReport(id: string, status: CommunityReportStatus) {
    const res = await axiosClient.patch(`/community/admin/reports/${id}`, {
      status,
    });
    return res.data?.data;
  },

  // ------------------------------------------------------------------ weekly
  async getWeeklyQuestions(params: { page?: number; take?: number }) {
    const res = await axiosClient.get("/community/admin/weekly", { params });
    return res.data?.data as IPagedResponse<ICommunityAdminPost>;
  },

  async createWeeklyQuestion(payload: ICommunityWeeklyPayload) {
    const res = await axiosClient.post("/community/admin/weekly", payload);
    return res.data?.data;
  },

  async updateWeeklyQuestion(id: string, payload: ICommunityWeeklyPayload) {
    const res = await axiosClient.patch(
      `/community/admin/weekly/${id}`,
      payload
    );
    return res.data?.data;
  },

  // -------------------------------------------------------- room suggestions
  async getRoomSuggestions(params: CommunityRoomSuggestionQuery) {
    const res = await axiosClient.get("/community/admin/room-suggestions", {
      params,
    });
    return res.data?.data as IPagedResponse<ICommunityRoomSuggestion>;
  },

  /**
   * Accept an ask by pointing it at a room that now exists.
   *
   * Approving does NOT create the room: a room needs a name in all five
   * languages, a slug and an image, none of which a free-text ask carries. The
   * flow is create the topic in the Topics screen, then link it here.
   */
  async approveRoomSuggestion(id: string, topicId: string, note?: string) {
    const res = await axiosClient.patch(
      `/community/admin/room-suggestions/${id}/approve`,
      { topicId, note }
    );
    return res.data?.data;
  },

  async declineRoomSuggestion(id: string, note?: string) {
    const res = await axiosClient.patch(
      `/community/admin/room-suggestions/${id}/decline`,
      { note }
    );
    return res.data?.data;
  },

  // --------------------------------------------------------------- sanctions
  async getSanctions(params: { page?: number; take?: number; userId?: string }) {
    const res = await axiosClient.get("/community/admin/sanctions", { params });
    return res.data?.data as IPagedResponse<ICommunitySanction>;
  },

  /** Every sanction ever applied to one reader — the violation history. */
  async getSanctionHistory(userId: string) {
    const res = await axiosClient.get(
      `/community/admin/sanctions/history/${userId}`
    );
    return res.data?.data as ICommunitySanction[];
  },

  async createSanction(payload: {
    userId: string;
    mutedUntil?: string;
    reason: string;
  }) {
    const res = await axiosClient.post("/community/admin/sanctions", payload);
    return res.data?.data as ICommunitySanction;
  },

  async revokeSanction(id: string) {
    const res = await axiosClient.delete(`/community/admin/sanctions/${id}`);
    return res.data?.data as ICommunitySanction;
  },
};
