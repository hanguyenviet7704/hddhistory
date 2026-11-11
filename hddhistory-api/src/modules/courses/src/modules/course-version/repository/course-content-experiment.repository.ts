import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CourseContentExperiment } from '../schema/course-content-experiment.schema';

@Injectable()
export class CourseContentExperimentRepository extends AbstractRepository<CourseContentExperiment> {
  protected readonly logger = new Logger(CourseContentExperimentRepository.name);

  constructor(
    @InjectModel(CourseContentExperiment.name)
    model: Model<CourseContentExperiment>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Đợt đang chạy có khoá này trong danh sách nhánh. Đây là query của ĐƯỜNG
   * SERVE, chạy trên mỗi lượt đọc nội dung của khoá nằm trong đợt, nên nó phải
   * ăn index `{ enabled, 'arms.courseId' }`.
   */
  async findRunningForCourse(
    courseId: string,
  ): Promise<CourseContentExperiment | null> {
    return this.model
      .findOne({ enabled: true, 'arms.courseId': courseId })
      .lean<CourseContentExperiment>();
  }

  /**
   * Danh sách khoá đang nằm trong một đợt đang bật. Đường serve dùng nó để
   * CHẶN SỚM: `factsFor` chạy trên mọi lượt đọc nội dung, và phần lớn khoá
   * không nằm trong đợt nào — không có bước này thì mỗi lượt đọc màn chính
   * phải trả thêm một query đợt.
   */
  async findEnabledArmCourseIds(): Promise<string[]> {
    const rows = await this.model
      .find({ enabled: true }, { 'arms.courseId': 1, _id: 0 })
      .lean<Array<{ arms?: Array<{ courseId: string }> }>>();

    return rows.flatMap(row => (row.arms ?? []).map(arm => arm.courseId));
  }

  /** Mới nhất trước — thứ tự bảng đợt trong admin. */
  async findAllNewestFirst(): Promise<CourseContentExperiment[]> {
    return this.model
      .find({})
      .sort({ createdAt: -1 })
      .lean<CourseContentExperiment[]>();
  }

  async findOneByKey(key: string): Promise<CourseContentExperiment | null> {
    return this.model.findOne({ key }).lean<CourseContentExperiment>();
  }
}
