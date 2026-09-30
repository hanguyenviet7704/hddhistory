import { OutputPracticeConversationStatus } from '../enum/output-practice-conversation.enum';

import type { OutputPracticeAiReply } from '../../ai/output-practice-ai.service';

export interface IOutputPracticeConversation {
  userId: string;
  sectionId: string;
  language: string;
  threadId: string;
  lastSeq: number;
  reply: OutputPracticeAiReply | null;
  status: OutputPracticeConversationStatus;
}
