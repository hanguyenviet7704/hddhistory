import { Injectable } from '@nestjs/common';

import { StreamMessageDto } from 'src/modules/socket/src/modules/gateway/dto/message.dto';
import { SocketServerEvent } from 'src/modules/socket/src/modules/gateway/interface/socket.interface';
import { SocketGateway } from 'src/modules/socket/src/modules/gateway/socket.gateway';
import { StreamService } from 'src/modules/socket/src/modules/stream/stream.service';

@Injectable()
export class MessageService {
  constructor(
    private readonly socketGateway: SocketGateway,
    private readonly streamService: StreamService,
  ) {}

  async get() {
    setInterval(() => {
      this.socketGateway.server.to('123').emit('newMessage', {
        user: 'system',
      });
    }, 1000);
  }

  async streamChat(dto: StreamMessageDto) {
    const { roomId, sender, message } = dto;

    // Báo client trong room rằng đã bắt đầu
    this.socketGateway.server
      .to(roomId)
      .emit(SocketServerEvent.CHAT_STARTED, { sender });

    // Stream từng chunk
    await this.streamService.streamMessage(
      message,
      chunk => {
        this.socketGateway.server
          .to(roomId)
          .emit(SocketServerEvent.CHAT_CHUNK, { sender, chunk });
      },
      () => {
        this.socketGateway.server
          .to(roomId)
          .emit(SocketServerEvent.CHAT_ENDED, { sender });
      },
    );

    return { status: 'streaming', roomId, sender };
  }
}
