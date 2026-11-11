import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateStudyThemeDto } from './dto/create-study-theme.dto';
import { GetListStudyThemeDto } from './dto/get-list-study-theme.dto';
import { UpdateStudyThemeDto } from './dto/update-study-theme.dto';
import { StudyThemeService } from './study-theme.service';

@ApiTags('STUDY-THEMES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'study-themes', version: '1' })
export class StudyThemeController {
  constructor(private readonly svc: StudyThemeService) {}

  // Public (mobile app) catalogue — active presets only.
  @Get('')
  findAll() {
    return this.svc.findActive();
  }

  // Admin table — includes inactive presets, paginated/filterable.
  @Get('all')
  findAllAdmin(@Query() dto: GetListStudyThemeDto) {
    return this.svc.findAll(dto);
  }

  @Post('')
  create(@Body() dto: CreateStudyThemeDto) {
    return this.svc.create(dto);
  }

  @Patch(':key')
  update(@Param('key') key: string, @Body() dto: UpdateStudyThemeDto) {
    return this.svc.update(key, dto);
  }

  @Delete(':key')
  remove(@Param('key') key: string) {
    return this.svc.remove(key);
  }
}
