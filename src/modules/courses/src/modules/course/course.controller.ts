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
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { CourseService } from './course.service';
import { CreateCourseDto } from './dto/create-course.dto';
import { GetListCourseDto } from './dto/get-list-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { UpdateRoadmapDto } from './dto/update-roadmap.dto';

@ApiTags('COURSES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses', version: '1' })
export class CourseController {
  constructor(private readonly svc: CourseService) {}

  @Post('')
  register(@Body() dto: CreateCourseDto) {
    return this.svc.create(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCourseDto) {
    return this.svc.update(id, dto);
  }

  @Put(':id/roadmap')
  updateRoadmap(@Param('id') id: string, @Body() dto: UpdateRoadmapDto) {
    return this.svc.updateRoadmap(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListCourseDto) {
    return this.svc.findAll(dto);
  }

  @Get('import/template')
  async getCourseImportTemplate(@Res() res: Response) {
    const buffer = await this.svc.getCourseImportTemplate();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="course-import-template.xlsx"',
    );
    res.send(buffer);
  }

  @Get('export')
  async exportCourses(@Res() res: Response) {
    const buffer = await this.svc.exportCourses();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="course-export.xlsx"',
    );
    res.send(buffer);
  }

  @Post('import')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importCourses(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.importCourses(file);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="course-import-result.xlsx"',
    );
    res.send(buffer);
  }

  /** `?version=v1.0.0` hoặc `?version=current` — chỉ panel dùng được. */
  @Get(':id')
  findOne(@Param('id') id: string, @Query('version') version?: string) {
    return this.svc.findOne(id, version);
  }

  /** `?version=v1.0.0` hoặc `?version=current` — chỉ panel dùng được. */
  @Get(':id/roadmap')
  findRoadmap(@Param('id') id: string, @Query('version') version?: string) {
    return this.svc.findRoadmap(id, version);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
