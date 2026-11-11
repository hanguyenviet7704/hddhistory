import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { DriveImportService } from './drive-import.service';
import { CreateDriveImportDto } from './dto/create-drive-import.dto';

@ApiTags('FILES-DRIVE-IMPORT')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'cloudflares/drive-imports', version: '1' })
export class DriveImportController {
  constructor(private readonly driveImportService: DriveImportService) {}

  @Post('')
  create(@Body() dto: CreateDriveImportDto) {
    return this.driveImportService.create(dto);
  }

  @Get('')
  findAll() {
    return this.driveImportService.findAll();
  }

  @Get(':jobId')
  findOne(@Param('jobId') jobId: string) {
    return this.driveImportService.findOne(jobId);
  }

  @Post(':jobId/cancel')
  cancel(@Param('jobId') jobId: string) {
    return this.driveImportService.cancel(jobId);
  }
}
