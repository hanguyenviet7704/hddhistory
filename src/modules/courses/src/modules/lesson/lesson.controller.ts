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
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateLessonDto } from './dto/create-lesson.dto';
import { GetListLessonDto } from './dto/get-list-lesson.dto';
import { UpdateLessonDto, UpdateLessonIndexDto } from './dto/update-lesson.dto';
import { LessonService } from './lesson.service';

@ApiTags('COURSES-LESSONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-lessons', version: '1' })
export class LessonController {
  constructor(
    private readonly svc: LessonService,
    private readonly configService: ConfigService,
  ) {}

  @Post('')
  register(@Body() dto: CreateLessonDto) {
    return this.svc.create(dto);
  }

  @Put('indexs')
  updateLessonIndex(@Body() dto: UpdateLessonIndexDto) {
    return this.svc.updateLessonIndex(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateLessonDto) {
    return this.svc.update(id, dto);
  }

  @Get()
  findAll(@Query() dto: GetListLessonDto) {
    return this.svc.findAll(dto);
  }

  @Get('import/template')
  async getLessonImportTemplate(@Res() res: Response) {
    const buffer = await this.svc.getLessonImportTemplate();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="lesson-import-template.xlsx"',
    );
    res.send(buffer);
  }

  @Get('export')
  async exportLessons(@Res() res: Response) {
    const buffer = await this.svc.exportLessons();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="lesson-export.xlsx"',
    );
    res.send(buffer);
  }

  @Post('import')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importLessons(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.importLessons(file);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="lesson-import-result.xlsx"',
    );
    res.send(buffer);
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
}
