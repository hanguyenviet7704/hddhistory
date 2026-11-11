import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { WeekRecap } from '../schema/week-recap.schema';

/**
 * The `week_recaps` collection — the only place that touches it.
 *
 * Reads are always narrowed by `userId`: a recap is one learner's week, and
 * every query here is either "mine" or a bug.
 */
@Injectable()
export class WeekRecapRepository extends AbstractRepository<WeekRecap> {
  protected readonly logger = new Logger(WeekRecapRepository.name);

  constructor(
    @InjectModel(WeekRecap.name) model: Model<WeekRecap>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findForWeek(userId: string, weekStart: Date): Promise<WeekRecap | null> {
    return this.model.findOne({ userId, weekStart }).lean<WeekRecap>().exec();
  }

  async findOwnedById(userId: string, id: string): Promise<WeekRecap | null> {
    return this.model
      .findOne({ _id: id, userId, hasActivity: true })
      .lean<WeekRecap>()
      .exec();
  }

  /**
   * Writes the week, or hands back the copy another request just wrote.
   *
   * `$setOnInsert` rather than `$set`: the unique index makes this a race
   * between two app opens, and the loser must not overwrite the winner's
   * document — doing so would reset `viewedAt` and pop the popup a second time
   * for a week the learner already dismissed.
   */
  async createIfAbsent(data: Partial<WeekRecap>): Promise<WeekRecap> {
    return this.model
      .findOneAndUpdate(
        { userId: data.userId, weekStart: data.weekStart },
        { $setOnInsert: data },
        { upsert: true, new: true, setDefaultsOnInsert: true, lean: true },
      )
      .lean<WeekRecap>()
      .exec() as unknown as WeekRecap;
  }

  /**
   * Rewrites a week the learner has never been shown.
   *
   * The `$exists: false` pair on both stamps is the whole safety of this: a
   * request that lands after the reader opened their poster finds nothing to
   * update and returns null, so numbers they have already seen — and may have
   * shared — can never be rewritten underneath them.
   */
  async replaceUnseen(params: {
    userId: string;
    weekStart: Date;
    data: Partial<WeekRecap>;
  }): Promise<WeekRecap | null> {
    return this.model
      .findOneAndUpdate(
        {
          userId: params.userId,
          weekStart: params.weekStart,
          viewedAt: { $exists: false },
          dismissedAt: { $exists: false },
        },
        { $set: params.data },
        { new: true, lean: true },
      )
      .lean<WeekRecap>()
      .exec();
  }

  /** Recaps worth showing, newest first. Quiet weeks never appear. */
  async findArchive(params: {
    userId: string;
    skip: number;
    take: number;
  }): Promise<WeekRecap[]> {
    return this.model
      .find({ userId: params.userId, hasActivity: true })
      .sort({ weekStart: -1 })
      .skip(params.skip)
      .limit(params.take)
      .lean<WeekRecap[]>()
      .exec();
  }

  async countArchive(userId: string): Promise<number> {
    return this.model.countDocuments({ userId, hasActivity: true }).exec();
  }

  /**
   * How many real recaps this learner already has — the basis of the next
   * one's "Tuần NN".
   *
   * Counted rather than stored on the user: the number is derivable, and a
   * counter on `users` would drift the first time a recap is written by a path
   * that forgets to bump it.
   */
  async nextWeekNumber(userId: string): Promise<number> {
    return (await this.countArchive(userId)) + 1;
  }

  /**
   * Stamps `viewedAt`, once.
   *
   * The `$exists: false` guard keeps the FIRST viewing: re-opening a poster
   * weeks later must not move the timestamp that the banner's "MỚI" pill is
   * dated from, or the pill would light up again on that later day.
   */
  async stampViewed(params: { userId: string; id: string }): Promise<void> {
    await this.model
      .updateOne(
        { _id: params.id, userId: params.userId, viewedAt: { $exists: false } },
        { $set: { viewedAt: new Date() } },
      )
      .exec();
  }

  /**
   * Stamps `dismissedAt` — and unlike [stampViewed], it MOVES on every "Để
   * sau". The popup re-offers each morning until the week is actually viewed,
   * and today's dismissal is what keeps it quiet for the rest of today; a
   * first-press-only stamp would fall out of date by tomorrow and the client
   * could no longer tell "muted today" from "muted last Tuesday".
   *
   * Guarded on `viewedAt` not existing: once the week has been seen there is
   * no popup left to mute, and a stray dismiss must not backdate anything.
   */
  async stampDismissed(params: { userId: string; id: string }): Promise<void> {
    await this.model
      .updateOne(
        { _id: params.id, userId: params.userId, viewedAt: { $exists: false } },
        { $set: { dismissedAt: new Date() } },
      )
      .exec();
  }
}
