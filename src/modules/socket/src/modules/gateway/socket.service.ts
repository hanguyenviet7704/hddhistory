import { Injectable } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

import { Configuration } from '@base/config/configuration';
import { JwtUtil } from '@utils/jwt';

import {
  coachRoomFor,
  IDataJoinRoom,
  SocketServerEvent,
} from './interface/socket.interface';
import { StreamService } from '../stream/stream.service';
import { StreamMessageDto } from './dto/message.dto';

@Injectable()
export class SocketService {
  constructor(
    private readonly jwt: JwtUtil,
    private readonly configuration: Configuration,
    private streamService: StreamService,
  ) {}

  async handleConnection(client: Socket) {
    // check JWT từ client.handshake.headers hoặc query
    const authHeader = client.handshake.headers['authorization'];

    if (!authHeader) {
      client.emit('error', { message: 'Unauthorized: Missing token' });
      client.disconnect();
      return;
    }

    /**
     * `JwtUtil.verify` RETURNS null on a bad token — it does not throw.
     *
     * This used to be a bare `await this.jwt.verify(token)` inside a try/catch,
     * which meant the catch could never fire and any two space-separated words
     * in the Authorization header were accepted as a login. Harmless while the
     * only traffic here was Output Practice's own echo; not harmless now that
     * the Coach previews a reader's conversation over this socket.
     *
     * Same null check the HTTP `AuthGuard` has always made — see its own
     * `decode === null` branch.
     */
    const token = authHeader.split(' ')[1];
    const decoded = token
      ? await this.jwt.verify<{ id?: string } | null>(token)
      : null;

    if (!decoded?.id) {
      client.emit('error', { message: 'Unauthorized: Invalid token' });
      client.disconnect();
      return;
    }

    /**
     * The reader's own room, joined SERVER-side from the verified token.
     *
     * Never from anything the client sends. `handleJoinRoom` will put a socket
     * into any room it asks for by name, so a room derived from a client-supplied
     * id would let one reader subscribe to another reader's coach session and
     * watch it being written.
     */
    client.data.userId = decoded.id;
    client.join(coachRoomFor(decoded.id));

    console.log(`Client connected: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  async handleJoinRoom(client: Socket, data: IDataJoinRoom | string) {
    const room = this.resolveRoom(data);

    if (!room) {
      client.emit(SocketServerEvent.JOIN_ROOM_ERROR, {
        message: 'room is required',
      });
      return;
    }

    client.join(room);
    client.emit(SocketServerEvent.JOINED_ROOM, { room });
    console.log(`Client ${client.id} joined room ${room}`);
  }

  async handleSendMessage(server: Server, data: any) {
    if (data.room) {
      // emit cho cả room
      server.to(data.room).emit(data.event, data.payload);
    } else {
      // broadcast toàn bộ
      server.emit(data.event, data.payload);
    }

    console.log(
      ` Emit data: ${data.event}, payload: ${JSON.stringify(data.payload)}`,
    );
  }

  async handleStreamMessage(server: Server, data: StreamMessageDto) {
    const { roomId, sender, message } = data;

    server.to(roomId).emit(SocketServerEvent.CHAT_STARTED, { sender });

    await this.streamService.streamMessage(
      message,
      chunk => {
        server.to(roomId).emit(SocketServerEvent.CHAT_CHUNK, { sender, chunk });
      },
      () => {
        server.to(roomId).emit(SocketServerEvent.CHAT_ENDED, { sender });
      },
    );
  }

  private resolveRoom(data: IDataJoinRoom | string) {
    if (!data) return '';

    if (typeof data === 'string') {
      const raw = data.trim();
      if (!raw) return '';

      try {
        const parsed = JSON.parse(raw) as IDataJoinRoom;
        if (typeof parsed?.room === 'string') {
          return parsed.room.trim();
        }
      } catch {
        return raw;
      }

      return raw;
    }

    return typeof data.room === 'string' ? data.room.trim() : '';
  }
}
