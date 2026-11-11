import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { SocketServerEvent } from 'src/modules/socket/src/modules/gateway/interface/socket.interface';
import { SocketGateway } from 'src/modules/socket/src/modules/gateway/socket.gateway';

import {
  OutputPracticeAiService,
  OutputPracticeAiReplyOption,
  OutputPracticeAiStreamEvent,
} from '../ai/output-practice-ai.service';
import {
  OutputPracticeConversationStatus,
  OutputPracticeSummaryDecisionValue,
} from '../conversation/enum/output-practice-conversation.enum';
import { OutputPracticeConversationService } from '../conversation/output-practice-conversation.service';
import { CreateOutputPracticeMessageDto } from './dto/create-output-practice-message.dto';
import { GetListOutputPracticeMessageDto } from './dto/get-list-output-practice-message.dto';
import { SendOutputPracticeInputDto } from './dto/send-output-practice-input.dto';
import {
  OutputPracticeMessageRole,
  OutputPracticeMessageType,
} from './enum/output-practice-message.enum';
import { OutputPracticeMessageRepository } from './repository/output-practice-message.repository';
import { OutputPracticeMessage } from './schema/output-practice-message.schema';

@Injectable()
export class OutputPracticeMessageService {
  constructor(
    private readonly outputPracticeMessageRepository: OutputPracticeMessageRepository,
    @Inject(forwardRef(() => OutputPracticeConversationService))
    private readonly outputPracticeConversationService: OutputPracticeConversationService,
    private readonly outputPracticeAiService: OutputPracticeAiService,
    private readonly socketGateway: SocketGateway,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  async create(
    dto: CreateOutputPracticeMessageDto,
  ): Promise<OutputPracticeMessage> {
    await this.outputPracticeConversationService.findOne(dto.conversationId);

    const seq = await this.outputPracticeConversationService.getNextSeq(
      dto.conversationId,
    );

    return this.outputPracticeMessageRepository.create(
      {
        ...dto,
        seq,
      },
      this.user,
    );
  }

  async send(
    dto: SendOutputPracticeInputDto,
  ): Promise<OutputPracticeMessage[]> {
    const conversation = await this.outputPracticeConversationService.findOne(
      dto.conversationId,
    );

    if (
      conversation.status === OutputPracticeConversationStatus.FINISHED ||
      conversation.status ===
        OutputPracticeConversationStatus.CONVERSATION_LIMIT_IN_MONTH
    ) {
      throw new BadRequestException('Conversation is not available for chat');
    }

    const aiInput = this.buildAiInput(dto);
    const statusUpdates: Promise<void>[] = [];
    let conversationStatus: OutputPracticeConversationStatus = conversation.status;

    const queueStatusUpdate = (status: OutputPracticeConversationStatus) => {
      if (conversationStatus === status) {
        return;
      }

      conversationStatus = status;
      statusUpdates.push(
        this.outputPracticeConversationService.updateStatus(
          dto.conversationId,
          status,
        ),
      );
    };

    if (dto.type === OutputPracticeMessageType.SUMMARY_DECISION) {
      const nextStatus =
        dto.value === OutputPracticeSummaryDecisionValue.STOP_PRACTICING_HERE
          ? OutputPracticeConversationStatus.FINISHED
          : OutputPracticeConversationStatus.ACTIVE;
      queueStatusUpdate(nextStatus);
    }

    if (dto.type === OutputPracticeMessageType.SELECT_OPTION) {
      queueStatusUpdate(OutputPracticeConversationStatus.ACTIVE);
    }

    const persistedMessages: OutputPracticeMessage[] = [];

    const persistedUserMessage = this.buildPersistedUserMessage(
      dto,
      conversation.reply?.options || [],
    );

    const userMessage = await this.create({
      conversationId: dto.conversationId,
      content: persistedUserMessage.content,
      type: persistedUserMessage.type,
      role: OutputPracticeMessageRole.USER,
    });
    persistedMessages.push(userMessage);

    let assistantContent = '';

    try {
      await this.outputPracticeAiService.streamConversation(
        {
          user_id: this.user.id,
          section_id: conversation.sectionId,
          thread_id: conversation.threadId,
          ...aiInput,
        },
        event => {
          this.forwardAiEventToRoom(dto.conversationId, event);

          if (
            event.type === 'metadata_update' &&
            typeof event.is_summary_turn === 'boolean'
          ) {
            const nextStatus = event.is_summary_turn
              ? OutputPracticeConversationStatus.SUMMARY_DECISION_PENDING
              : OutputPracticeConversationStatus.ACTIVE;

            if (conversationStatus !== OutputPracticeConversationStatus.FINISHED) {
              queueStatusUpdate(nextStatus);
            }
          }

          if (event.type === 'stream') {
            assistantContent += event.content || '';
          }
        },
      );
    } catch (error: any) {
      this.forwardAiEventToRoom(dto.conversationId, {
        type: 'error',
        content: error?.message || 'Unexpected AI stream error',
      });
      throw error;
    } finally {
      if (statusUpdates.length) {
        await Promise.allSettled(statusUpdates);
      }
    }

    if (assistantContent.trim()) {
      const assistantMessage = await this.create({
        conversationId: dto.conversationId,
        content: assistantContent,
        type: OutputPracticeMessageType.MESSAGE,
        role: OutputPracticeMessageRole.ASSISTANT,
      });
      persistedMessages.push(assistantMessage);
    }

    return persistedMessages;
  }

  async deleteByConversationIds(conversationIds: string[]) {
    await this.outputPracticeMessageRepository.deleteManyByConversationIds(
      conversationIds,
    );
  }

  private forwardAiEventToRoom(
    conversationId: string,
    event: OutputPracticeAiStreamEvent,
  ) {
    if (!this.socketGateway.server) {
      return;
    }

    const room = `${conversationId}`.trim();
    if (!room) {
      return;
    }

    this.socketGateway.server
      .to(room)
      .emit(SocketServerEvent.OUTPUT_PRACTICE_EVENT, {
        conversationId: room,
        ...event,
      });
  }

  private buildPersistedUserMessage(
    dto: SendOutputPracticeInputDto,
    options: OutputPracticeAiReplyOption[],
  ) {
    switch (dto.type) {
      case OutputPracticeMessageType.MESSAGE:
        return {
          content: dto.message!.trim(),
          type: OutputPracticeMessageType.MESSAGE,
        };
      case OutputPracticeMessageType.SELECT_OPTION: {
        const selectedOption = options.find(option => option.value === dto.value);

        return {
          content: selectedOption?.label || `${dto.value ?? ''}`,
          type: OutputPracticeMessageType.SELECT_OPTION,
        };
      }
      case OutputPracticeMessageType.SUMMARY_DECISION:
        return {
          content: this.getSummaryDecisionLabel(dto.value),
          type: OutputPracticeMessageType.SUMMARY_DECISION,
        };
      default:
        return {
          content: '',
          type: OutputPracticeMessageType.MESSAGE,
        };
    }
  }

  private getSummaryDecisionLabel(value?: number) {
    switch (value) {
      case OutputPracticeSummaryDecisionValue.STOP_PRACTICING_HERE:
        return 'Stop practicing here';
      case OutputPracticeSummaryDecisionValue.START_A_NEW_PRACTICE:
        return 'Start a new practice';
      default:
        return `${value ?? ''}`;
    }
  }

  private buildAiInput(dto: SendOutputPracticeInputDto) {
    switch (dto.type) {
      case OutputPracticeMessageType.MESSAGE: {
        const message = dto.message?.trim();
        if (!message) {
          throw new BadRequestException('message is required for type=message');
        }
        return {
          type: OutputPracticeMessageType.MESSAGE,
          message,
        };
      }
      case OutputPracticeMessageType.SELECT_OPTION:
      case OutputPracticeMessageType.SUMMARY_DECISION: {
        if (typeof dto.value !== 'number') {
          throw new BadRequestException(
            'value is required for select_option and summary_decision',
          );
        }
        return {
          type: dto.type,
          value: dto.value,
        };
      }
      default:
        throw new BadRequestException('Unsupported input type');
    }
  }

  async findAll(dto: GetListOutputPracticeMessageDto) {
    await this.outputPracticeConversationService.findOne(dto.conversationId);
    return this.outputPracticeMessageRepository.findOption(dto);
  }

  async findOne(id: string): Promise<OutputPracticeMessage> {
    const message = await this.outputPracticeMessageRepository.findOne({
      _id: id,
    });
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    await this.outputPracticeConversationService.findOne(
      message.conversationId,
    );

    return message;
  }

  async remove(id: string) {
    const message = await this.findOne(id);
    return this.outputPracticeMessageRepository.deleteOne({ _id: message._id });
  }
}
