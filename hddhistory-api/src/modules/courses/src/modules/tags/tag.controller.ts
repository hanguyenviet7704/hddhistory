import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Put,
  Delete,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateTagDto } from './dto/create-tag.dto';
import { GetListTagDto } from './dto/get-list-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { TagService } from './tag.service';

@ApiTags('COURSES-TAGS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-tags', version: '1' })
export class TagController {
  constructor(
    private readonly svc: TagService,
    private readonly configService: ConfigService,
  ) {}

  @Post('')
  register(@Body() dto: CreateTagDto) {
    return this.svc.create(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTagDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListTagDto) {
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
