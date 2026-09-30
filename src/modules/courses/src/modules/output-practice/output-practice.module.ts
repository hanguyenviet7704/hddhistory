import { forwardRef, Module } from '@nestjs/common';

import { OutputPracticeConversationModule } from './conversation/output-practice-conversation.module';
import { OutputPracticeMessageModule } from './message/output-practice-message.module';

@Module({
  imports: [OutputPracticeConversationModule, OutputPracticeMessageModule],
})
export class OutputPracticeModule {}
