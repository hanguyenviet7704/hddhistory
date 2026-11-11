import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';
import { v4 as uuidv4 } from 'uuid';

import { RequestService } from '@base/service/request.service';

import {
  CreateUserVideoLessonNoteDto,
  GetListUserVideoLessonActivityDto,
  UpdateUserVideoLessonNoteDto,
} from './dto/user-video-lesson-activity.dto';
import { IUserVideoLessonNote } from './interface/user-video-lesson-activity.interface';
import { UserVideoLessonActivityRepository } from './repository/user-video-lesson-activity.repository';
import { UserVideoLessonActivity } from './schema/user-video-lesson-activity.schema';
import { LessonType } from '../../../../lesson/enum/lesson.enum';
import { LessonRepository } from '../../../../lesson/repository/lesson.repository';

@Injectable()
export class UserVideoLessonActivityService {
  constructor(
    private readonly activityRepository: UserVideoLessonActivityRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private async ensureVideoLesson(courseId: string, lessonId: string) {
    const lesson = await this.lessonRepository.findOne(
      { _id: lessonId, courseId },
      { _id: 1, courseId: 1, type: 1 },
      { lean: true },
    );

    if (!lesson) {
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LESSON.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    }

    if (lesson.type !== LessonType.VIDEO) {
      throw new BadRequestException('lessonId must reference a video lesson');
    }

    return lesson;
  }

  async findAll(dto: GetListUserVideoLessonActivityDto) {
    if (dto.lessonId && dto.courseId) {
      await this.ensureVideoLesson(dto.courseId, dto.lessonId);
    }

    return this.activityRepository.findOption({
      ...dto,
      userId: this.user.id,
    });
  }

  async addNote(
    dto: CreateUserVideoLessonNoteDto,
  ): Promise<IUserVideoLessonNote> {
    await this.ensureVideoLesson(dto.courseId, dto.lessonId);

    return this.activityRepository.create(
      {
        id: uuidv4(),
        userId: this.user.id,
        courseId: dto.courseId,
        nodeId: dto.nodeId,
        lessonId: dto.lessonId,
        content: dto.content,
        atSecond: dto.atSecond,
      },
      this.user,
    );
  }

  async findOne(id: string): Promise<UserVideoLessonActivity> {
    const note = await this.activityRepository.findOneByComposite({
      id,
      userId: this.user.id,
    });

    if (!note) {
      throw new NotFoundException('Video lesson note not found');
    }

    return note as UserVideoLessonActivity;
  }

  async updateNote(id: string, dto: UpdateUserVideoLessonNoteDto): Promise<IUserVideoLessonNote> {
    const note = await this.findOne(id);
    const updatePayload: Partial<UserVideoLessonActivity> = {};

    if (typeof dto.content === 'string') {
      updatePayload.content = dto.content;
    }
    if (typeof dto.atSecond === 'number') {
      updatePayload.atSecond = dto.atSecond;
    }

    await this.activityRepository.updateOne(
      { _id: note._id },
      updatePayload,
      this.user,
    );

    return this.findOne(id);
  }

  async deleteNote(id: string): Promise<{ id: string }> {
    const note = await this.findOne(id);
    await this.activityRepository.deleteOne({ _id: note._id });

    return { id };
  }
}
