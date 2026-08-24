part of '../../../community.dart';

@lazySingleton
@RestApi()
abstract class CommunityApi {
  @factoryMethod
  factory CommunityApi(@Named(DIKey.appDio) Dio dio) = _CommunityApi;

  @GET(AppEndpoint.communityFeed)
  Future<BaseResponse<CommunityFeedModel>> getFeed({
    @Query('page') required int page,
    @Query('take') required int take,
    @Query('topicId') String? topicId,
    @Query('followingOnly') bool? followingOnly,
    @Query('sort') String? sort,
    @Query('anchorAt') String? anchorAt,
  });

  @GET(AppEndpoint.communityTopics)
  Future<BaseResponse<CommunityTopicListModel>> getTopics();

  @GET(AppEndpoint.communityTopicById)
  Future<BaseResponse<CommunityTopicModel>> getTopic(@Path('id') String id);

  @POST(AppEndpoint.communityTopicFollow)
  Future<void> followTopic(@Path('id') String id);

  @DELETE(AppEndpoint.communityTopicFollow)
  Future<void> unfollowTopic(@Path('id') String id);

  @GET(AppEndpoint.communityPostById)
  Future<BaseResponse<CommunityPostModel>> getPost(@Path('id') String id);

  @POST(AppEndpoint.communityPosts)
  Future<BaseResponse<CommunityPostModel>> createPost(@Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.communityPostById)
  Future<void> deletePost(@Path('id') String id);

  @GET(AppEndpoint.communityPostComments)
  Future<BaseResponse<CommunityCommentPageModel>> getComments(
    @Path('id') String postId, {
    @Query('page') required int page,
    @Query('take') required int take,
  });

  @POST(AppEndpoint.communityPostComments)
  Future<BaseResponse<CommunityCommentPageModel>> createComment(
    @Path('id') String postId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(AppEndpoint.communityCommentById)
  Future<void> deleteComment(@Path('id') String id);

  @POST(AppEndpoint.communityReactions)
  Future<void> react(@Body() Map<String, dynamic> body);

  // A DELETE with a body: the reaction is identified by target + kind, not by
  // an id of its own, which is what keeps the write idempotent server-side.
  @DELETE(AppEndpoint.communityReactions)
  Future<void> unreact(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.communityHidden)
  Future<void> hide(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.communityReports)
  Future<void> report(@Body() Map<String, dynamic> body);

  @GET(AppEndpoint.communitySaved)
  Future<BaseResponse<CommunitySavedPageModel>> getSaved({
    @Query('page') required int page,
    @Query('take') required int take,
  });

  // `data` comes back null when no question is open — the feed then hides the
  // weekly card rather than rendering an empty one.
  @GET(AppEndpoint.communityWeekly)
  Future<BaseResponse<CommunityWeeklyModel>> getWeekly();

  @GET(AppEndpoint.communityNotifications)
  Future<BaseResponse<CommunityNotificationPageModel>> getNotifications({
    @Query('page') required int page,
    @Query('take') required int take,
  });

  // Just the badge number — cheaper than pulling a page of rows for a count.
  @GET(AppEndpoint.communityNotificationsUnread)
  Future<BaseResponse<CommunityUnreadCountModel>> getUnreadCount();

  @POST(AppEndpoint.communityNotificationsRead)
  Future<void> markNotificationsRead(@Body() Map<String, dynamic> body);

  @GET(AppEndpoint.communityMyStatus)
  Future<BaseResponse<CommunityMemberStatusModel>> getMemberStatus();
}
