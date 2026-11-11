import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { SocketModule } from 'src/modules/socket/socket.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OutputPracticeMessageController } from './output-practice-message.controller';
import { OutputPracticeMessageService } from './output-practice-message.service';
import { OutputPracticeAiModule } from '../ai/output-practice-ai.module';
import { OutputPracticeConversationModule } from '../conversation/output-practice-conversation.module';
import { OutputPracticeMessageRepository } from './repository/output-practice-message.repository';
import {
  OutputPracticeMessage,
  OutputPracticeMessageSchema,
} from './schema/output-practice-message.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OutputPracticeMessage.name, schema: OutputPracticeMessageSchema },
    ]),
    forwardRef(() => AuthModule),
    OutputPracticeAiModule,
    SocketModule,
    LoggerModule,
    forwardRef(() => OutputPracticeConversationModule),
  ],
  controllers: [OutputPracticeMessageController],
  providers: [OutputPracticeMessageService, OutputPracticeMessageRepository],
  exports: [OutputPracticeMessageService, OutputPracticeMessageRepository],
})
export class OutputPracticeMessageModule {}
