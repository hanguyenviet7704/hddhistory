import { Module } from '@nestjs/common';

import { SocketModule } from 'src/modules/socket/socket.module';
import { StreamModule } from 'src/modules/socket/src/modules/stream/stream.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { MessageController } from './message.controller';
import { MessageService } from './message.service';

@Module({
  imports: [SocketModule, AuthModule, StreamModule],
  controllers: [MessageController],
  providers: [MessageService],
})
export class MessageModule {}
