import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateReanchorReasonDto } from './dto/create-reanchor-reason.dto';
import { GetListReanchorReasonDto } from './dto/get-list-reanchor-reason.dto';
import { ImportReanchorReasonDto } from './dto/import-reanchor-reason.dto';
import { UpdateReanchorReasonDto } from './dto/update-reanchor-reason.dto';
import { ReanchorReasonService } from './reanchor-reason.service';

@ApiTags('REANCHOR-REASONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'reanchor-reasons', version: '1' })
export class ReanchorReasonController {
  constructor(private readonly svc: ReanchorReasonService) {}

  @Post('')
  create(@Body() dto: CreateReanchorReasonDto) {
    return this.svc.create(dto);
  }

  // Bulk export/import (declared before ':id' so 'export' isn't captured as an id).
  @Get('export')
  export() {
    return this.svc.exportAll();
  }

  @Post('import')
  import(@Body() dto: ImportReanchorReasonDto) {
    return this.svc.importReplace(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateReanchorReasonDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListReanchorReasonDto) {
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
