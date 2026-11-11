import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateOutputPracticeConversationDto } from './dto/create-output-practice-conversation.dto';
import { GetListOutputPracticeConversationDto } from './dto/get-list-output-practice-conversation.dto';
import { IOutputPracticeConversationUsage } from './interface/output-practice-conversation-usage.interface';
import { OutputPracticeConversationService } from './output-practice-conversation.service';
import { OutputPracticeConversation } from './schema/output-practice-conversation.schema';

@ApiTags('COURSES-OUTPUT-PRACTICE-CONVERSATIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-output-practice-conversations', version: '1' })
export class OutputPracticeConversationController {
  constructor(private readonly svc: OutputPracticeConversationService) {}

  @Post('')
  register(
    @Body() dto: CreateOutputPracticeConversationDto,
  ): Promise<OutputPracticeConversation> {
    return this.svc.create(dto);
  }

  @Get('')
  findAll(@Query() dto: GetListOutputPracticeConversationDto) {
    return this.svc.findAll(dto);
  }

  @Get('section/:sectionId')
  findBySectionId(
    @Param('sectionId') sectionId: string,
  ): Promise<OutputPracticeConversation | null> {
    return this.svc.findBySectionId(sectionId);
  }

  @Get('section/:sectionId/usage')
  getUsage(
    @Param('sectionId') sectionId: string,
  ): Promise<IOutputPracticeConversationUsage> {
    return this.svc.getUsage(sectionId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
