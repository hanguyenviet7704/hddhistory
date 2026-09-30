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

import { GetListOutputPracticeMessageDto } from './dto/get-list-output-practice-message.dto';
import { SendOutputPracticeInputDto } from './dto/send-output-practice-input.dto';
import { OutputPracticeMessageService } from './output-practice-message.service';
import { OutputPracticeMessage } from './schema/output-practice-message.schema';

@ApiTags('COURSES-OUTPUT-PRACTICE-MESSAGES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-output-practice-messages', version: '1' })
export class OutputPracticeMessageController {
  constructor(private readonly svc: OutputPracticeMessageService) {}

  @Post('send')
  send(
    @Body() dto: SendOutputPracticeInputDto,
  ): Promise<OutputPracticeMessage[]> {
    return this.svc.send(dto);
  }

  @Get('')
  findAll(@Query() dto: GetListOutputPracticeMessageDto) {
    return this.svc.findAll(dto);
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
