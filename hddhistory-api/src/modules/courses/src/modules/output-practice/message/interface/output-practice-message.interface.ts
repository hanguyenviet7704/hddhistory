import {
  OutputPracticeMessageRole,
  OutputPracticeMessageType,
} from '../enum/output-practice-message.enum';

export interface IOutputPracticeMessage {
  conversationId: string;
  seq: number;
  content: string;
  type: OutputPracticeMessageType;
  role: OutputPracticeMessageRole;
}
