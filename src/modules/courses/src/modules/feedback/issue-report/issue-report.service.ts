import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { RequestService } from '@base/service/request.service';
import { OrderType } from '@utils/type/orderByType';

import { CreateIssueReportDto } from './dto/create-issue-report.dto';
import { GetIssueReportsDto } from './dto/get-issue-reports.dto';
import { IssueReportRepository } from './repository/issue-report.repository';
import { Course } from '../../course/schema/course.schema';
import { Keypoint } from '../../keypoint/schema/keypoint.schema';
import { Lesson } from '../../lesson/schema/lesson.schema';

@Injectable()
export class IssueReportService {
  constructor(
    private readonly issueReportRepository: IssueReportRepository,
    private readonly requestService: RequestService,
    @InjectModel(Course.name)
    private readonly courseModel: Model<Course>,
    @InjectModel(Keypoint.name)
    private readonly keypointModel: Model<Keypoint>,
    @InjectModel(Lesson.name)
    private readonly lessonModel: Model<Lesson>,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  async create(dto: CreateIssueReportDto) {
    const userId = this.user?.id;
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    const lesson = await this.lessonModel.findById(dto.lessonId).lean();
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const courseId = dto.courseId || lesson.courseId;
    let courseTitle = undefined;
    if (courseId) {
      const course = await this.courseModel.findById(courseId, { title: 1 }).lean();
      if (course) {
        courseTitle = course.title;
      }
    }

    let keypointTitle = undefined;
    if (dto.keypointId) {
      const keypoint = await this.keypointModel.findById(dto.keypointId, { title: 1 }).lean();
      if (keypoint) {
        keypointTitle = keypoint.title;
      }
    }

    const reportData = {
      userId,
      lessonId: dto.lessonId,
      lessonTitle: lesson.title,
      courseId,
      courseTitle,
      keypointId: dto.keypointId,
      keypointTitle,
      reasons: dto.reasons,
      comment: dto.comment,
    };

    return this.issueReportRepository.create(reportData, this.user);
  }

  async getReports(dto: GetIssueReportsDto) {
    const where: any = {};
    if (dto.lessonId) {
      where.lessonId = dto.lessonId;
    }
    if (dto.courseId) {
      where.courseId = dto.courseId;
    }
    if (dto.userId) {
      where.userId = dto.userId;
    }
    if (dto.search) {
      where.comment = { $regex: dto.search, $options: 'i' };
    }

    return this.issueReportRepository.paginateQuery({
      where,
      orderBy: dto.orderBy || 'createdAt',
      order: dto.order || OrderType.DESC,
      page: dto.page,
      take: dto.take,
    });
  }

  async getReportById(id: string) {
    const report = await this.issueReportRepository.findById(id);
    if (!report) {
      throw new NotFoundException('Report not found');
    }
    return report;
  }

  async deleteReport(id: string) {
    const report = await this.issueReportRepository.findById(id);
    if (!report) {
      throw new NotFoundException('Report not found');
    }
    return this.issueReportRepository.deleteOne({ _id: report._id });
  }
}
