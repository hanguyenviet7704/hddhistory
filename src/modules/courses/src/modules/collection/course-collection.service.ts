import { Injectable, NotFoundException } from '@nestjs/common';

import {
  CreateCourseCollectionDto,
  GetListCourseCollectionDto,
  ReorderCourseCollectionDto,
  UpdateCourseCollectionDto,
} from './dto/course-collection.dto';
import {
  CourseCollectionSlot,
  CourseCollectionStatus,
} from './enum/course-collection.enum';
import { CourseCollectionRepository } from './repository/course-collection.repository';

@Injectable()
export class CourseCollectionService {
  constructor(private readonly repository: CourseCollectionRepository) {}

  async create(dto: CreateCourseCollectionDto) {
    const slot = dto.slot ?? CourseCollectionSlot.BOTTOM;

    return this.repository.create({
      title: dto.title,
      status: dto.status ?? CourseCollectionStatus.DRAFT,
      slot,
      // A new row lands at the end of its slot rather than at 0, so creating
      // one never silently reshuffles the rows the editor already arranged.
      index: dto.index ?? (await this.repository.getNextIndex(slot)),
      segmentIds: dto.segmentIds ?? [],
      courseIds: dto.courseIds ?? [],
    } as any);
  }

  async update(id: string, dto: UpdateCourseCollectionDto) {
    const existing = await this.repository.findById(id);
    if (!existing) throw new NotFoundException('Course collection not found');

    const payload: Record<string, any> = {};
    // Only fields actually sent are written: the admin form saves one section
    // at a time, and copying `undefined` over a field would blank it.
    if (dto.title !== undefined) payload.title = dto.title;
    if (dto.status !== undefined) payload.status = dto.status;
    if (dto.slot !== undefined) payload.slot = dto.slot;
    if (dto.index !== undefined) payload.index = dto.index;
    if (dto.segmentIds !== undefined) payload.segmentIds = dto.segmentIds;
    if (dto.courseIds !== undefined) payload.courseIds = dto.courseIds;

    return this.repository.findOneAndUpdate({ _id: id } as any, {
      $set: payload,
    });
  }

  async findAll(dto: GetListCourseCollectionDto) {
    return this.repository.findAllOrdered(dto);
  }

  async findOne(id: string) {
    const collection = await this.repository.findById(id);
    if (!collection) throw new NotFoundException('Course collection not found');
    return collection;
  }

  async reorder(dto: ReorderCourseCollectionDto) {
    await this.repository.applyOrder(dto.ids);
    return { success: true };
  }

  async remove(id: string) {
    const existing = await this.repository.findById(id);
    if (!existing) throw new NotFoundException('Course collection not found');

    await this.repository.deleteOne({ _id: id } as any);
    return { success: true };
  }
}
