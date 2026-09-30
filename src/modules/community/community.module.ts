import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CommunityChatController } from './src/modules/chat/community-chat.controller';
import { CommunityChatService } from './src/modules/chat/community-chat.service';
import { CommunityChatMembershipRepository } from './src/modules/chat/repository/community-chat-membership.repository';
import { CommunityChatMessageRepository } from './src/modules/chat/repository/community-chat-message.repository';
import { CommunityChatRoomRepository } from './src/modules/chat/repository/community-chat-room.repository';
import {
  CommunityChatMembership,
  CommunityChatMembershipSchema,
} from './src/modules/chat/schema/community-chat-membership.schema';
import {
  CommunityChatMessage,
  CommunityChatMessageSchema,
} from './src/modules/chat/schema/community-chat-message.schema';
import {
  CommunityChatRoom,
  CommunityChatRoomSchema,
} from './src/modules/chat/schema/community-chat-room.schema';
import { CommunityChatGuideController } from './src/modules/chat-guide/community-chat-guide.controller';
import { CommunityChatGuideService } from './src/modules/chat-guide/community-chat-guide.service';
import { CommunityChatGuideRepository } from './src/modules/chat-guide/repository/community-chat-guide.repository';
import {
  CommunityChatGuide,
  CommunityChatGuideSchema,
} from './src/modules/chat-guide/schema/community-chat-guide.schema';
import { CommunityCommentController } from './src/modules/comment/community-comment.controller';
import { CommunityCommentService } from './src/modules/comment/community-comment.service';
import { CommunityCommentRepository } from './src/modules/comment/repository/community-comment.repository';
import {
  CommunityComment,
  CommunityCommentSchema,
} from './src/modules/comment/schema/community-comment.schema';
import { CommunityNotificationController } from './src/modules/notification/community-notification.controller';
import { CommunityNotificationService } from './src/modules/notification/community-notification.service';
import { CommunityNotificationRepository } from './src/modules/notification/repository/community-notification.repository';
import {
  CommunityNotification,
  CommunityNotificationSchema,
} from './src/modules/notification/schema/community-notification.schema';
import { CommunityOfficialProfileController } from './src/modules/official-profile/community-official-profile.controller';
import { CommunityOfficialProfileService } from './src/modules/official-profile/community-official-profile.service';
import { CommunityOfficialProfileRepository } from './src/modules/official-profile/repository/community-official-profile.repository';
import {
  CommunityOfficialProfile,
  CommunityOfficialProfileSchema,
} from './src/modules/official-profile/schema/community-official-profile.schema';
import { CommunityPostController } from './src/modules/post/community-post.controller';
import { CommunityPostService } from './src/modules/post/community-post.service';
import { CommunityPostRepository } from './src/modules/post/repository/community-post.repository';
import {
  CommunityPost,
  CommunityPostSchema,
} from './src/modules/post/schema/community-post.schema';
import { CommunityReactionController } from './src/modules/reaction/community-reaction.controller';
import { CommunityReactionService } from './src/modules/reaction/community-reaction.service';
import { CommunityHiddenItemRepository } from './src/modules/reaction/repository/community-hidden-item.repository';
import { CommunityReactionRepository } from './src/modules/reaction/repository/community-reaction.repository';
import { CommunityThreadMuteRepository } from './src/modules/reaction/repository/community-thread-mute.repository';
import { CommunityTopicFollowRepository } from './src/modules/reaction/repository/community-topic-follow.repository';
import {
  CommunityHiddenItem,
  CommunityHiddenItemSchema,
} from './src/modules/reaction/schema/community-hidden-item.schema';
import {
  CommunityReaction,
  CommunityReactionSchema,
} from './src/modules/reaction/schema/community-reaction.schema';
import {
  CommunityThreadMute,
  CommunityThreadMuteSchema,
} from './src/modules/reaction/schema/community-thread-mute.schema';
import {
  CommunityTopicFollow,
  CommunityTopicFollowSchema,
} from './src/modules/reaction/schema/community-topic-follow.schema';
import { CommunityReportController } from './src/modules/report/community-report.controller';
import { CommunityReportService } from './src/modules/report/community-report.service';
import { CommunityReportRepository } from './src/modules/report/repository/community-report.repository';
import {
  CommunityReport,
  CommunityReportSchema,
} from './src/modules/report/schema/community-report.schema';
import { CommunityRoomSuggestionController } from './src/modules/room-suggestion/community-room-suggestion.controller';
import { CommunityRoomSuggestionService } from './src/modules/room-suggestion/community-room-suggestion.service';
import { CommunityRoomSuggestionRepository } from './src/modules/room-suggestion/repository/community-room-suggestion.repository';
import {
  CommunityRoomSuggestion,
  CommunityRoomSuggestionSchema,
} from './src/modules/room-suggestion/schema/community-room-suggestion.schema';
import { CommunitySanctionController } from './src/modules/sanction/community-sanction.controller';
import { CommunitySanctionService } from './src/modules/sanction/community-sanction.service';
import { CommunitySanctionRepository } from './src/modules/sanction/repository/community-sanction.repository';
import {
  CommunitySanction,
  CommunitySanctionSchema,
} from './src/modules/sanction/schema/community-sanction.schema';
import { CommunityTopicController } from './src/modules/topic/community-topic.controller';
import { CommunityTopicService } from './src/modules/topic/community-topic.service';
import { CommunityTopicRepository } from './src/modules/topic/repository/community-topic.repository';
import {
  CommunityTopic,
  CommunityTopicSchema,
} from './src/modules/topic/schema/community-topic.schema';
import { CommunityAuthorService } from './src/service/community-author.service';
import { CommunityTopicStatsScheduler } from './src/service/community-topic-stats.scheduler';

/**
 * The community forum: topics, posts, comments, reactions, reports, moderation.
 *
 * One Nest module for the whole feature even though the folders nest like the
 * rest of `src/modules`. The submodules are not independent the way
 * `courses/`'s are — a post hides its comment thread, a resolved report hides a
 * post, a new comment notifies the post's author — so splitting them into seven
 * modules would mean seven `forwardRef`s around a cycle rather than clearer
 * boundaries. Layering (controller → service → repository) is still enforced
 * inside each folder.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CommunityTopic.name, schema: CommunityTopicSchema },
      { name: CommunityPost.name, schema: CommunityPostSchema },
      { name: CommunityComment.name, schema: CommunityCommentSchema },
      { name: CommunityReaction.name, schema: CommunityReactionSchema },
      { name: CommunityThreadMute.name, schema: CommunityThreadMuteSchema },
      { name: CommunityTopicFollow.name, schema: CommunityTopicFollowSchema },
      { name: CommunityHiddenItem.name, schema: CommunityHiddenItemSchema },
      { name: CommunityReport.name, schema: CommunityReportSchema },
      { name: CommunitySanction.name, schema: CommunitySanctionSchema },
      {
        name: CommunityOfficialProfile.name,
        schema: CommunityOfficialProfileSchema,
      },
      {
        name: CommunityNotification.name,
        schema: CommunityNotificationSchema,
      },
      {
        name: CommunityRoomSuggestion.name,
        schema: CommunityRoomSuggestionSchema,
      },
      { name: CommunityChatRoom.name, schema: CommunityChatRoomSchema },
      { name: CommunityChatMessage.name, schema: CommunityChatMessageSchema },
      { name: CommunityChatGuide.name, schema: CommunityChatGuideSchema },
      {
        name: CommunityChatMembership.name,
        schema: CommunityChatMembershipSchema,
      },
    ]),
    // AuthGuard's dependencies, plus UserRepository (author identity, push
    // tokens) and FirebaseService (the push itself).
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [
    CommunityTopicController,
    CommunityPostController,
    CommunityCommentController,
    CommunityReactionController,
    CommunityReportController,
    CommunitySanctionController,
    CommunityOfficialProfileController,
    CommunityNotificationController,
    CommunityRoomSuggestionController,
    CommunityChatController,
    CommunityChatGuideController,
  ],
  providers: [
    CommunityTopicRepository,
    CommunityPostRepository,
    CommunityCommentRepository,
    CommunityReactionRepository,
    CommunityThreadMuteRepository,
    CommunityTopicFollowRepository,
    CommunityHiddenItemRepository,
    CommunityReportRepository,
    CommunitySanctionRepository,
    CommunityOfficialProfileRepository,
    CommunityNotificationRepository,
    CommunityRoomSuggestionRepository,
    CommunityChatRoomRepository,
    CommunityChatMessageRepository,
    CommunityChatGuideRepository,
    CommunityChatMembershipRepository,
    CommunityAuthorService,
    CommunityTopicService,
    CommunityPostService,
    CommunityCommentService,
    CommunityReactionService,
    CommunityReportService,
    CommunitySanctionService,
    CommunityOfficialProfileService,
    CommunityNotificationService,
    CommunityRoomSuggestionService,
    CommunityChatService,
    CommunityChatGuideService,
    CommunityTopicStatsScheduler,
  ],
  exports: [CommunityTopicService, CommunityPostService],
})
export class CommunityModule {}
