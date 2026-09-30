import { Module } from '@nestjs/common';

import { MessageModule } from './src/modules/message/message.module';

@Module({
  imports: [MessageModule],
})
export class ChatModule {}
