import { Module } from '@nestjs/common';

import { SocketGateway } from './src/modules/gateway/socket.gateway';
import { SocketService } from './src/modules/gateway/socket.service';
import { StreamModule } from './src/modules/stream/stream.module';
import { AuthModule } from '../user/src/modules/auth/auth.module';

@Module({
  imports: [AuthModule, StreamModule],
  providers: [SocketGateway, SocketService],
  exports: [SocketGateway],
})
export class SocketModule {}
