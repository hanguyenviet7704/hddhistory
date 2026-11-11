import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CourseVersionActivation } from '../schema/course-version-activation.schema';

@Injectable()
export class CourseVersionActivationRepository extends AbstractRepository<CourseVersionActivation> {
  protected readonly logger = new Logger(
    CourseVersionActivationRepository.name,
  );

  constructor(
    @InjectModel(CourseVersionActivation.name)
    model: Model<CourseVersionActivation>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Đóng mọi đoạn đang mở của khoá. Dùng `updateMany` chứ không `updateOne` vì
   * nếu từng có lúc ghi hỏng và để lại hai đoạn mở thì phải đóng cả hai —
   * một đoạn mở sót lại làm mọi cửa sổ sau nó chồng lên nhau và số của tất cả
   * các tag đều sai, chứ không riêng tag đó.
   */
  async closeOpenWindows(courseId: string, at: Date): Promise<number> {
    const res = await this.model.updateMany(
      { courseId, to: null },
      { $set: { to: at } },
    );

    return res.modifiedCount ?? 0;
  }

  async openWindow(params: {
    courseId: string;
    versionId: string;
    tag: string;
    from: Date;
  }): Promise<void> {
    await this.model.create({ ...params, to: null });
  }

  /** Đoạn đang mở của khoá, nếu có. */
  async findOpenWindow(
    courseId: string,
  ): Promise<CourseVersionActivation | null> {
    return this.model
      .findOne({ courseId, to: null })
      .lean<CourseVersionActivation>();
  }

  /** Toàn bộ dải cửa sổ của khoá, cũ nhất trước. */
  async findByCourse(courseId: string): Promise<CourseVersionActivation[]> {
    return this.model
      .find({ courseId })
      .sort({ from: 1 })
      .lean<CourseVersionActivation[]>();
  }
}
