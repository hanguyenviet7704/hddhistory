import {
  ConflictException,
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { CreateOutputPracticeConversationDto } from './dto/create-output-practice-conversation.dto';
import { GetListOutputPracticeConversationDto } from './dto/get-list-output-practice-conversation.dto';
import { OutputPracticeConversationStatus } from './enum/output-practice-conversation.enum';
import { IOutputPracticeConversationUsage } from './interface/output-practice-conversation-usage.interface';
import { OutputPracticeConversationRepository } from './repository/output-practice-conversation.repository';
import { OutputPracticeConversation } from './schema/output-practice-conversation.schema';
import { RoadmapRepository } from '../../course/repository/roadmap.repository';
import { ContentSource } from '../../course-version/content-source.service';
import { UserLessonPracticeService } from '../../learning-import/user-lesson-practice.service';
import { LessonType } from '../../lesson/enum/lesson.enum';
import { LessonRepository } from '../../lesson/repository/lesson.repository';
import { OutputPracticeAiService } from '../ai/output-practice-ai.service';
import {
  OutputPracticeMessageRole,
  OutputPracticeMessageType,
} from '../message/enum/output-practice-message.enum';
import { OutputPracticeMessageService } from '../message/output-practice-message.service';
import { OutputPracticeUsageRepository } from '../usage/repository/output-practice-usage.repository';

@Injectable()
export class OutputPracticeConversationService {
  private static readonly MONTHLY_LIMIT = 3;
  private readonly logger = new Logger(OutputPracticeConversationService.name);

  constructor(
    private readonly outputPracticeConversationRepository: OutputPracticeConversationRepository,
    private readonly outputPracticeUsageRepository: OutputPracticeUsageRepository,
    private readonly outputPracticeAiService: OutputPracticeAiService,
    @Inject(forwardRef(() => OutputPracticeMessageService))
    private readonly outputPracticeMessageService: OutputPracticeMessageService,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly requestService: RequestService,
    private readonly userLessonPracticeService: UserLessonPracticeService,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  async create(
    dto: CreateOutputPracticeConversationDto,
  ): Promise<OutputPracticeConversation> {
    const hasRemainingQuota = await this.hasRemainingConversationQuota(
      dto.sectionId,
    );

    if (!hasRemainingQuota) {
      return this.attachConversationLimitToLatestConversation(
        dto.sectionId,
        dto.language,
      );
    }

    const aiConfig = await this.resolveAiConfig(dto.sectionId);

    const aiStart = await this.outputPracticeAiService.startConversation({
      user_id: this.user.id,
      section_id: dto.sectionId,
      language: dto.language,
      ai_config: aiConfig,
    });
    const hasReplyOptions = !!aiStart.reply?.options?.length;

    let conversation: OutputPracticeConversation;

    try {
      conversation = await this.outputPracticeConversationRepository.create(
        {
          sectionId: dto.sectionId,
          language: dto.language,
          threadId: aiStart.thread_id,
          userId: this.user.id,
          lastSeq: 0,
          reply: aiStart.reply || null,
          status: hasReplyOptions
            ? OutputPracticeConversationStatus.SELECT_OPTION_PENDING
            : OutputPracticeConversationStatus.ACTIVE,
        },
        this.user,
      );
    } catch (error: any) {
      if (error?.code === 11000) {
        throw new ConflictException('Thread id already exists');
      }
      throw error;
    }

    const quotaConsumed = await this.consumeConversationQuota(dto.sectionId);

    if (!quotaConsumed) {
      await this.outputPracticeConversationRepository.deleteOne({
        _id: conversation._id,
        userId: this.user.id,
      });

      return this.attachConversationLimitToLatestConversation(
        dto.sectionId,
        dto.language,
      );
    }

    const openingText = aiStart.reply?.content?.trim();

    if (openingText) {
      try {
        await this.outputPracticeMessageService.create({
          conversationId: conversation._id.toString(),
          content: openingText,
          type: OutputPracticeMessageType.MESSAGE,
          role: OutputPracticeMessageRole.ASSISTANT,
        });
      } catch {
        await this.outputPracticeConversationRepository.deleteOne({
          _id: conversation._id,
          userId: this.user.id,
        });
        throw new InternalServerErrorException(
          'Cannot persist opening assistant message',
        );
      }
    }

    await this.cleanupStaleConversations(dto.sectionId, conversation._id.toString());

    return conversation;
  }

  async findAll(dto: GetListOutputPracticeConversationDto) {
    return this.outputPracticeConversationRepository.findOption(
      dto,
      this.user.id,
    );
  }

  async findOne(id: string): Promise<OutputPracticeConversation> {
    const conversation =
      await this.outputPracticeConversationRepository.findOne({
        _id: id,
        userId: this.user.id,
      });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return conversation;
  }

  async findBySectionId(
    sectionId: string,
  ): Promise<OutputPracticeConversation | null> {
    return this.outputPracticeConversationRepository.findLatestBySectionId(
      sectionId,
      this.user.id,
    );
  }

  async getUsage(sectionId: string): Promise<IOutputPracticeConversationUsage> {
    const usedCount = await this.outputPracticeUsageRepository.getUsedCount(
      this.user.id,
      sectionId,
      this.getCurrentMonthKey(),
    );

    const remainingInThisMonth = Math.max(
      0,
      OutputPracticeConversationService.MONTHLY_LIMIT - usedCount,
    );

    return {
      remainingInThisMonth,
      monthlyLimit: OutputPracticeConversationService.MONTHLY_LIMIT,
    };
  }

  async getNextSeq(conversationId: string) {
    const nextSeq =
      await this.outputPracticeConversationRepository.incrementLastSeq(
        conversationId,
        this.user.id,
      );

    if (nextSeq === undefined) {
      throw new NotFoundException('Conversation not found.');
    }

    return nextSeq;
  }

  async updateStatus(
    conversationId: string,
    status: OutputPracticeConversationStatus,
  ) {
    await this.outputPracticeConversationRepository.updateOne(
      {
        _id: conversationId,
        userId: this.user.id,
      },
      {
        status,
      } as any,
    );
  }

  async remove(id: string) {
    const conversation = await this.findOne(id);
    await this.outputPracticeMessageService.deleteByConversationIds([
      conversation._id.toString(),
    ]);
    return this.outputPracticeConversationRepository.deleteOne({
      _id: conversation._id,
      userId: this.user.id,
    });
  }

  private async resolveAiConfig(sectionId: string) {
    // A lesson the reader generated has no roadmap node and no OUTPUT lesson to
    // read a config off, so its prompt is built from the lesson itself. Checked
    // first because the roadmap query below would find nothing and quietly
    // return '' -- a practice session with no idea what it is practising.
    if (UserLessonPracticeService.parseSectionId(sectionId)) {
      return this.userLessonPracticeService.buildAiConfig(
        sectionId,
        this.user.id,
      );
    }

    const roadmap =
      (await this.roadmapRepository.findOne(
        { 'levels.nodes.id': sectionId },
        { levels: 1 },
        { lean: true },
      )) || {};

    let outputId = '';

    for (const level of (roadmap as any).levels || []) {
      const node = (level?.nodes || []).find(
        (item: any) => item?.id?.toString?.() === sectionId,
      );

      if (node) {
        outputId = node?.outputId?.toString?.() || '';
        break;
      }
    }

    if (!outputId) {
      return '';
    }

    // AIConfig là prompt điều khiển hội thoại AI, tức nội dung do biên tập
    // viết -- nên nó theo tag đang phát hành, không phải bản đang sửa.
    const versionId = await this.contentSource.versionForEntity(
      'lesson',
      String(outputId),
      this.requestService.headers,
      null,
      this.user?.id,
    );

    const outputLesson = versionId
      ? await this.contentSource.getLesson(String(outputId), versionId)
      : await this.lessonRepository.findOne(
          { _id: outputId, type: LessonType.OUTPUT },
          { AIConfig: 1 },
          { lean: true },
        );

    return (outputLesson as any)?.AIConfig?.trim?.() || '';
  }

  private async hasRemainingConversationQuota(sectionId: string) {
    const usedCount = await this.outputPracticeUsageRepository.getUsedCount(
      this.user.id,
      sectionId,
      this.getCurrentMonthKey(),
    );

    return usedCount < OutputPracticeConversationService.MONTHLY_LIMIT;
  }

  private async consumeConversationQuota(sectionId: string) {
    // We consume quota only after the new conversation is saved successfully,
    // so a failed AI/start flow does not burn one monthly attempt.
    return this.outputPracticeUsageRepository.consumeMonthlyAttempt(
      this.user.id,
      sectionId,
      this.getCurrentMonthKey(),
      OutputPracticeConversationService.MONTHLY_LIMIT,
      this.user,
    );
  }

  private async cleanupStaleConversations(
    sectionId: string,
    keepConversationId: string,
  ) {
    const staleConversationIds =
      await this.outputPracticeConversationRepository.findStaleConversationIds(
        sectionId,
        this.user.id,
        keepConversationId,
      );

    if (!staleConversationIds.length) {
      return;
    }

    try {
      // Keep only the latest conversation for each section.
      // Usage history stays in output_practice_usages, so old conversations
      // can be removed without breaking the monthly quota.
      await this.outputPracticeMessageService.deleteByConversationIds(
        staleConversationIds,
      );
      await this.outputPracticeConversationRepository.deleteManyByIds(
        staleConversationIds,
        this.user.id,
      );
    } catch (error: any) {
      this.logger.error(
        `Cannot cleanup stale conversations for section ${sectionId}: ${error?.message || error}`,
      );
    }
  }

  private getCurrentMonthKey(now = new Date()) {
    // The month key is the reset boundary.
    // Example: 2026-03 and 2026-04 are counted independently.
    const month = `${now.getMonth() + 1}`.padStart(2, '0');

    return `${now.getFullYear()}-${month}`;
  }

  private async attachConversationLimitToLatestConversation(
    sectionId: string,
    language: string,
  ) {
    const latestConversation = await this.findBySectionId(sectionId);

    if (!latestConversation) {
      // Defensive fallback. In normal flow, a user who has exhausted the quota
      // should already have at least one conversation in this section.
      return this.createFallbackConversationLimitConversation(sectionId, language);
    }

    await this.updateStatus(
      latestConversation._id.toString(),
      OutputPracticeConversationStatus.CONVERSATION_LIMIT_IN_MONTH,
    );

    await this.appendMonthlyLimitMessages(
      latestConversation._id.toString(),
      language,
    );

    return this.findOne(latestConversation._id.toString());
  }

  private async createFallbackConversationLimitConversation(
    sectionId: string,
    language: string,
  ) {
    const conversation = await this.outputPracticeConversationRepository.create(
      {
        sectionId,
        language,
        // This fallback only exists to keep the API contract stable when the
        // latest conversation is unexpectedly missing.
        threadId: this.buildLocalThreadId(sectionId),
        userId: this.user.id,
        lastSeq: 0,
        reply: null,
        status: OutputPracticeConversationStatus.CONVERSATION_LIMIT_IN_MONTH,
      },
      this.user,
    );

    await this.appendMonthlyLimitMessages(conversation._id.toString(), language);

    return conversation;
  }

  private async appendMonthlyLimitMessages(
    conversationId: string,
    language: string,
  ) {
    // This simulates the user action that tried to start one more practice,
    // then the assistant response that explains the monthly limit.
    await this.outputPracticeMessageService.create({
      conversationId,
      content: 'Start a new practice',
      type: OutputPracticeMessageType.MESSAGE,
      role: OutputPracticeMessageRole.USER,
    });

    await this.outputPracticeMessageService.create({
      conversationId,
      content: this.getConversationLimitExceededMessage(language),
      type: OutputPracticeMessageType.MESSAGE,
      role: OutputPracticeMessageRole.ASSISTANT,
    });
  }

  private buildLocalThreadId(sectionId: string) {
    return `local-limit-${this.user.id}-${sectionId}-${Date.now()}`;
  }

  private getConversationLimitExceededMessage(language: string) {
    return this.isVietnamese(language)
      ? 'Bạn đã hoàn thành tất cả lượt luyện tập trong tháng này. Đừng lo, quay lại vào tháng tới với 3 lượt mới!'
      : "You've finished all your practice this month. No worries, come back next month for 3 new ones!";
  }

  private isVietnamese(language: string) {
    return language?.trim().toLowerCase().startsWith('vi');
  }
}
