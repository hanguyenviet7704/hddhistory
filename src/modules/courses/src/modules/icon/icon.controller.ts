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

import { CreateIconDto } from './dto/create-icon.dto';
import { GetListIconDto } from './dto/get-list-icon.dto';
import { UpdateIconDto } from './dto/update-icon.dto';
import { IconService } from './icon.service';

@ApiTags('COURSES-ICONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-icons', version: '1' })
export class IconController {
  constructor(
    private readonly iconService: IconService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  create(@Body() createIconDto: CreateIconDto) {
    return this.iconService.create(createIconDto);
  }

  @Get()
  findAll(@Query() getListIconDto: GetListIconDto) {
    return this.iconService.findAll(getListIconDto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.iconService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateIconDto: UpdateIconDto) {
    return this.iconService.update(id, updateIconDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.iconService.remove(id);
  }
}
