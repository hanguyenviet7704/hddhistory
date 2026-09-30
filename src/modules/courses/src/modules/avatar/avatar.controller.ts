import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Query,
  UseGuards,
  Put,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { AvatarService } from './avatar.service';
import { CreateAvatarDto } from './dto/create-avatar.dto';
import { GetListAvatarDto } from './dto/get-list-avatar.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';

@ApiTags('COURSES-AVATARS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-avatars', version: '1' })
export class AvatarController {
  constructor(
    private readonly avatarService: AvatarService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  create(@Body() createAvatarDto: CreateAvatarDto) {
    return this.avatarService.create(createAvatarDto);
  }

  @Get()
  findAll(@Query() getListAvatarDto: GetListAvatarDto) {
    return this.avatarService.findAll(getListAvatarDto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.avatarService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateAvatarDto: UpdateAvatarDto) {
    return this.avatarService.update(id, updateAvatarDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.avatarService.remove(id);
  }
}
