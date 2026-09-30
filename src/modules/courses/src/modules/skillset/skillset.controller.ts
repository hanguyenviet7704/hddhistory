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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateSkillsetDto } from './dto/create-skillset.dto';
import { GetListSkillsetDto } from './dto/get-list-skillset.dto';
import { UpdateSkillsetDto } from './dto/update-skillset.dto';
import { SkillsetService } from './skillset.service';

@ApiTags('SKILLSETS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'skillsets', version: '1' })
export class SkillsetController {
  constructor(private readonly svc: SkillsetService) {}

  @Post('')
  create(@Body() dto: CreateSkillsetDto) {
    return this.svc.create(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateSkillsetDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListSkillsetDto) {
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
