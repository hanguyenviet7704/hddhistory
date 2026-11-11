import { Controller, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { MessageService } from './message.service';
@ApiTags('CHATS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'chats/messages', version: '1' })
export class MessageController {
  constructor(private readonly messageService: MessageService) {}

  // @Get()
  // async get() {
  //   return this.messageService.get();
  // }

  // @Post('')
  // async streamChat(@Body() dto: ChatMessageDto) {
  //   return this.messageService.streamChat(dto);
  // }
}
