import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CreateHabitLibraryDto } from './dto/create-habit-library.dto';
import { GetListHabitLibraryDto } from './dto/get-list-habit-library.dto';
import { ImportHabitLibraryDto } from './dto/import-habit-library.dto';
import { UpdateHabitLibraryDto } from './dto/update-habit-library.dto';
import { HabitLibraryService } from './habit-library.service';

@ApiTags('HABITS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'habits', version: '1' })
export class HabitLibraryController {
  constructor(private readonly svc: HabitLibraryService) {}

  @Post('')
  create(
    @Body() dto: CreateHabitLibraryDto,
    @Req() req: Request & { user?: IUser },
  ) {
    return this.svc.create(dto, req.user);
  }

  // Bulk export/import (declared before ':id' so 'export' isn't captured as an id).
  @Get('export')
  export() {
    return this.svc.exportAll();
  }

  @Post('import')
  import(
    @Body() dto: ImportHabitLibraryDto,
    @Req() req: Request & { user?: IUser },
  ) {
    return this.svc.importReplace(dto, req.user);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateHabitLibraryDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListHabitLibraryDto) {
    return this.svc.findAll(dto);
  }

  // Declared before ':id' alone so the static tail can't be eaten by it.
  @Get(':id/courses')
  coursesForHabit(@Param('id') id: string) {
    return this.svc.coursesForHabit(id);
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
