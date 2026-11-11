import { Injectable } from '@nestjs/common';
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

import { StreamMessageDto } from './dto/message.dto';
import {
  IDataJoinRoom,
  IDataSendMessage,
  SocketClientEvent,
} from './interface/socket.interface';
import { SocketService } from './socket.service';

@WebSocketGateway({ cors: true })
@Injectable()
export class SocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly socketService: SocketService) {}

  async handleConnection(client: Socket) {
    await this.socketService.handleConnection(client);
  }

  async handleDisconnect(client: Socket) {
    await this.socketService.handleDisconnect(client);
  }

  @SubscribeMessage(SocketClientEvent.JOIN_ROOM)
  async handleJoinRoom(
    @MessageBody() data: IDataJoinRoom,
    @ConnectedSocket() client: Socket,
  ) {
    await this.socketService.handleJoinRoom(client, data);
  }

  @SubscribeMessage(SocketClientEvent.SEND_MESSAGE)
  async handleSendMessage(@MessageBody() data: IDataSendMessage) {
    await this.socketService.handleSendMessage(this.server, data);
  }

  // gửi message streaming
  @SubscribeMessage(SocketClientEvent.STREAM_MESSAGE)
  async handleStreamMessage(@MessageBody() data: StreamMessageDto) {
    await this.socketService.handleStreamMessage(this.server, data);
  }
}
