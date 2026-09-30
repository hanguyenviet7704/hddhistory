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

import { CourseCollectionService } from './course-collection.service';
import {
  CreateCourseCollectionDto,
  GetListCourseCollectionDto,
  ReorderCourseCollectionDto,
  UpdateCourseCollectionDto,
} from './dto/course-collection.dto';

@ApiTags('COURSE-COLLECTIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'course-collections', version: '1' })
export class CourseCollectionController {
  constructor(private readonly svc: CourseCollectionService) {}

  @Post('')
  create(@Body() dto: CreateCourseCollectionDto) {
    return this.svc.create(dto);
  }

  // Declared before `:id` so the literal path is not captured as an id.
  @Put('reorder')
  reorder(@Body() dto: ReorderCourseCollectionDto) {
    return this.svc.reorder(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCourseCollectionDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAll(@Query() dto: GetListCourseCollectionDto) {
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
