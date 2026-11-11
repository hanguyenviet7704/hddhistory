import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Put,
  Delete,
  Res,
  UseGuards,
  UploadedFile,
  Query,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateLearningItemDto } from './dto/create-learning-item.dto';
import { DailyWarmUpTaggingResultDto } from './dto/daily-warm-up-tagging.dto';
import { GetListLearningItemDto } from './dto/get-learning-item.dto';
import {
  UpdateLearningItemDto,
  UpdateLearningItemIndexDto,
} from './dto/update-learning-item.dto';
import { LearningItemService } from './learning-item.service';

@ApiTags('COURSES-LEARNING-ITEMS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-learning-items', version: '1' })
export class LearningItemController {
  constructor(private readonly svc: LearningItemService) {}

  @Post('')
  register(@Body() dto: CreateLearningItemDto) {
    return this.svc.create(dto);
  }

  @Post('import-theories')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importTheories(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.importTheories(file);
    this.sendExcel(res, buffer, 'theory-import-result.xlsx');
  }

  @Post('import-exercises')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importExercises(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.importExercises(file);
    this.sendExcel(res, buffer, 'exercise-import-result.xlsx');
  }

  @Get('export-theories')
  async exportTheories(@Res() res: Response) {
    const buffer = await this.svc.exportTheories();
    this.sendExcel(res, buffer, 'theory-export.xlsx');
  }

  @Get('export-exercises')
  async exportExercises(@Res() res: Response) {
    const buffer = await this.svc.exportExercises();
    this.sendExcel(res, buffer, 'exercise-export.xlsx');
  }

  @Put('indexs')
  updateLearningItemIndex(@Body() dto: UpdateLearningItemIndexDto) {
    return this.svc.updateLearningItemIndex(dto);
  }

  // Static-path routes are declared before `:id` so Nest doesn't treat
  // `daily-warm-up-tagging` as an `:id` param.
  @Get('daily-warm-up-tagging/preview')
  @ApiOperation({
    summary:
      'Dry-run the daily warm-up auto-tagging rule across all lessons (no writes).',
  })
  @ApiOkResponse({ type: DailyWarmUpTaggingResultDto })
  previewDailyWarmUpTagging(): Promise<DailyWarmUpTaggingResultDto> {
    return this.svc.previewDailyWarmUpTagging();
  }

  @Post('daily-warm-up-tagging/apply')
  @ApiOperation({
    summary:
      'Apply the daily warm-up auto-tagging rule across all lessons (full sync, idempotent).',
  })
  @ApiOkResponse({ type: DailyWarmUpTaggingResultDto })
  applyDailyWarmUpTagging(): Promise<DailyWarmUpTaggingResultDto> {
    return this.svc.applyDailyWarmUpTagging();
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateLearningItemDto) {
    return this.svc.update(id, dto);
  }

  @Get()
  findAll(@Query() dto: GetListLearningItemDto) {
    return this.svc.findAll(dto);
  }

  /** `?version=v1.0.0` hoặc `?version=current` — chỉ panel dùng được. */
  @Get(':id')
  findOne(@Param('id') id: string, @Query('version') version?: string) {
    return this.svc.findOne(id, version);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }

  private sendExcel(res: Response, buffer: Buffer, filename: string) {
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${filename}"`,
    );
    res.send(buffer);
  }
}
