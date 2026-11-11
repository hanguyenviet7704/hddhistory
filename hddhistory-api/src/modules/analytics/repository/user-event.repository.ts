import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { UserEventKind } from '../enum/analytics.enum';
import {
  INameCount,
  IUserEvent,
  IUserEventSession,
  IUserEventSummary,
} from '../interface/user-event.interface';
import { UserEvent } from '../schema/user-event.schema';

interface IRangeFilter {
  userId: string;
  from?: Date;
  to?: Date;
  appEnv?: string;
}

const escapeRegex = (value: string) =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

@Injectable()
export class UserEventRepository extends AbstractRepository<UserEvent> {
  protected readonly logger = new Logger(UserEventRepository.name);

  constructor(
    @InjectModel(UserEvent.name) model: Model<UserEvent>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // `ordered: false` so one bad document never drops the rest of the batch.
  async insertManyEvents(events: Partial<IUserEvent>[]): Promise<number> {
    if (!events.length) return 0;

    try {
      const inserted = await this.model.insertMany(events, { ordered: false });
      return inserted.length;
    } catch (error: any) {
      // Partial failure (a validation error on one document) still inserted the
      // rest — report that instead of failing the request, or the app would
      // retry a batch that is already stored.
      const insertedDocs = error?.insertedDocs;
      if (Array.isArray(insertedDocs)) {
        this.logger.warn(
          `insertManyEvents partial: ${insertedDocs.length}/${events.length} stored`,
        );
        return insertedDocs.length;
      }
      throw error;
    }
  }

  private buildMatch(filter: IRangeFilter): FilterQuery<UserEvent> {
    const where: FilterQuery<UserEvent> = {
      userId: new Types.ObjectId(filter.userId),
    };

    if (filter.from || filter.to) {
      where.clientTs = {};
      if (filter.from) where.clientTs.$gte = filter.from;
      if (filter.to) where.clientTs.$lte = filter.to;
    }

    if (filter.appEnv) where.appEnv = filter.appEnv;

    return where;
  }

  /**
   * How many times one event fired in a window, split by one of its `params`
   * values — e.g. `noti_tap` grouped by `noti_type`, which is what the
   * notification screen counts clicks with.
   *
   * Counts EVENTS, not distinct users: two taps on two different days are two
   * clicks, the same way an impression counter works.
   *
   * `appEnv` is required rather than optional on purpose. It is the first key of
   * the `{ appEnv, name, clientTs }` index, and Mongo cannot use a compound
   * index without its prefix — omitting it would turn this into a collection
   * scan over a write-heavy collection.
   *
   * Ranged on `clientTs` (when the app fired it), matching every other read
   * here. `serverTs` can be minutes or a restart later, which would put a tap
   * in the wrong day at a window edge.
   */
  async countEventsByParam(params: {
    name: string;
    paramKey: string;
    appEnv: string;
    from: Date;
    to: Date;
  }): Promise<Record<string, number>> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      {
        $match: {
          appEnv: params.appEnv,
          name: params.name,
          clientTs: { $gte: params.from, $lte: params.to },
        },
      },
      { $group: { _id: `$params.${params.paramKey}`, count: { $sum: 1 } } },
    ]);

    const counts: Record<string, number> = {};
    for (const row of rows) {
      // An event fired by a build that did not send the param yet groups under
      // null. Dropped rather than counted under a made-up key -- it cannot be
      // attributed to anything, and a bucket named "null" on the screen would
      // only invite someone to read it as a real type.
      if (!row._id) continue;
      counts[row._id] = row.count;
    }

    return counts;
  }

  /**
   * Distinct USERS per value of one event param — the people-sized sibling of
   * [[countEventsByParam]].
   *
   * The A/B readout needs this rather than raw event counts: a paywall reopened
   * five times is one person deciding, and counting it five times moves a
   * conversion rate without anybody's behaviour having changed.
   */
  async countUsersByParam(params: {
    name: string;
    paramKey: string;
    appEnv: string;
    from: Date;
    to: Date;
    /**
     * Extra `params.*` equality the event must satisfy — e.g. the experiment
     * key, so a window that straddles two runs does not pool their arms. Left
     * out, every event carrying the grouped param is counted.
     */
    whereParams?: Record<string, string>;
  }): Promise<Record<string, number>> {
    const extra = Object.fromEntries(
      Object.entries(params.whereParams ?? {}).map(([key, value]) => [
        `params.${key}`,
        value,
      ]),
    );

    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      {
        $match: {
          appEnv: params.appEnv,
          name: params.name,
          clientTs: { $gte: params.from, $lte: params.to },
          ...extra,
        },
      },
      {
        $group: {
          _id: { value: `$params.${params.paramKey}`, userId: '$userId' },
        },
      },
      { $group: { _id: '$_id.value', count: { $sum: 1 } } },
    ]);

    const counts: Record<string, number> = {};
    for (const row of rows) {
      // Same rule as countEventsByParam: a build that does not send the param
      // yet groups under null and is dropped rather than invented into a
      // bucket -- during a staged rollout that bucket would be most of them.
      if (!row._id) continue;
      counts[row._id] = row.count;
    }

    return counts;
  }

  // Everything the behaviour tab's header needs, in one round trip.
  async aggregateSummary(
    filter: IRangeFilter,
    funnelPrefix: string,
  ): Promise<IUserEventSummary> {
    const match = this.buildMatch(filter);

    const [result] = await this.model.aggregate([
      { $match: match },
      {
        $facet: {
          totals: [
            {
              $group: {
                _id: null,
                totalEvents: { $sum: 1 },
                lastActiveAt: { $max: '$clientTs' },
                platforms: { $addToSet: '$platform' },
                appVersions: { $addToSet: '$appVersion' },
              },
            },
          ],
          activeDays: [
            {
              $group: {
                _id: {
                  $dateToString: { format: '%Y-%m-%d', date: '$clientTs' },
                },
              },
            },
            { $count: 'count' },
          ],
          sessions: [
            {
              $group: {
                _id: '$sessionId',
                startAt: { $min: '$clientTs' },
                endAt: { $max: '$clientTs' },
              },
            },
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                totalDurationMs: {
                  $sum: { $subtract: ['$endAt', '$startAt'] },
                },
              },
            },
          ],
          topScreens: [
            { $match: { kind: UserEventKind.SCREEN } },
            { $group: { _id: '$name', count: { $sum: 1 } } },
            { $sort: { count: -1, _id: 1 } },
            { $limit: 10 },
          ],
          topEvents: [
            { $match: { kind: UserEventKind.EVENT } },
            { $group: { _id: '$name', count: { $sum: 1 } } },
            { $sort: { count: -1, _id: 1 } },
            { $limit: 10 },
          ],
          funnelFirstSeen: [
            {
              $match: {
                name: { $regex: `^${escapeRegex(funnelPrefix)}` },
              },
            },
            { $group: { _id: '$name', at: { $min: '$clientTs' } } },
            { $sort: { at: 1 } },
          ],
        },
      },
    ]);

    const totals = result?.totals?.[0];
    const sessions = result?.sessions?.[0];
    const sessionCount = sessions?.count ?? 0;
    const totalDurationMs = sessions?.totalDurationMs ?? 0;

    const toNameCount = (rows: any[]): INameCount[] =>
      (rows ?? []).map((row) => ({ name: row._id, count: row.count }));

    return {
      totalEvents: totals?.totalEvents ?? 0,
      activeDays: result?.activeDays?.[0]?.count ?? 0,
      sessions: sessionCount,
      totalDurationMs,
      avgSessionMs: sessionCount ? Math.round(totalDurationMs / sessionCount) : 0,
      lastActiveAt: totals?.lastActiveAt ?? null,
      platforms: (totals?.platforms ?? []).filter(Boolean),
      appVersions: (totals?.appVersions ?? []).filter(Boolean),
      topScreens: toNameCount(result?.topScreens),
      topEvents: toNameCount(result?.topEvents),
      funnelFirstSeen: (result?.funnelFirstSeen ?? []).map((row: any) => ({
        name: row._id,
        at: row.at,
      })),
    };
  }

  // Sessions, newest first. Not cursor-paginated: a 90-day range is a few
  // hundred sessions at most, and `limit` caps it.
  async aggregateSessions(
    filter: IRangeFilter,
    limit: number,
  ): Promise<IUserEventSession[]> {
    const match = this.buildMatch(filter);

    return this.model.aggregate([
      { $match: match },
      { $sort: { clientTs: 1 } },
      {
        $group: {
          _id: '$sessionId',
          startAt: { $min: '$clientTs' },
          endAt: { $max: '$clientTs' },
          eventCount: { $sum: 1 },
          // Screen names only, in fire order — `$$REMOVE` drops the non-screen
          // events instead of leaving nulls in the array.
          screens: {
            $push: {
              $cond: [
                { $eq: ['$kind', UserEventKind.SCREEN] },
                '$name',
                '$$REMOVE',
              ],
            },
          },
          appEnv: { $last: '$appEnv' },
          appVersion: { $last: '$appVersion' },
          platform: { $last: '$platform' },
        },
      },
      {
        $project: {
          _id: 0,
          sessionId: '$_id',
          startAt: 1,
          endAt: 1,
          eventCount: 1,
          appEnv: 1,
          appVersion: 1,
          platform: 1,
          durationMs: { $subtract: ['$endAt', '$startAt'] },
          firstScreen: { $arrayElemAt: ['$screens', 0] },
          lastScreen: { $arrayElemAt: ['$screens', -1] },
        },
      },
      { $sort: { startAt: -1 } },
      { $limit: limit },
    ]);
  }

  // Events inside one session, oldest first, keyset-paginated on clientTs.
  async findSessionEvents(params: {
    userId: string;
    sessionId: string;
    namePrefix?: string;
    kind?: UserEventKind;
    cursor?: Date;
    limit: number;
  }): Promise<UserEvent[]> {
    const where: FilterQuery<UserEvent> = {
      userId: new Types.ObjectId(params.userId),
      sessionId: params.sessionId,
    };

    if (params.namePrefix) {
      where.name = { $regex: `^${escapeRegex(params.namePrefix)}` };
    }
    if (params.kind) where.kind = params.kind;
    if (params.cursor) where.clientTs = { $gt: params.cursor };

    return this.model
      .find(where)
      .select('name kind clientTs params -_id')
      .sort({ clientTs: 1 })
      .limit(params.limit)
      .lean() as unknown as UserEvent[];
  }

  // ------------------------------------------------- so sánh phiên bản khoá

  /**
   * Khớp thời gian theo NHIỀU đoạn rời nhau.
   *
   * Bảng so sánh phiên bản gán event về tag theo cửa sổ thời gian, và một tag
   * bị roll back rồi quay lại có nhiều đoạn — lấy `min(from)`..`max(to)` cho
   * gọn sẽ nuốt trọn cả quãng của tag nằm giữa và cộng số của nó vào đây.
   */
  private windowMatch(windows: { from: Date; to?: Date | null }[], now: Date) {
    return {
      $or: windows.map(w => ({
        clientTs: { $gte: w.from, $lte: w.to ?? now },
      })),
    };
  }

  private windowScope(params: {
    appEnv: string;
    windows: { from: Date; to?: Date | null }[];
    whereParams?: Record<string, string>;
    now?: Date;
  }) {
    const extra = Object.fromEntries(
      Object.entries(params.whereParams ?? {}).map(([key, value]) => [
        `params.${key}`,
        value,
      ]),
    );

    return {
      appEnv: params.appEnv,
      ...extra,
      ...this.windowMatch(params.windows, params.now ?? new Date()),
    };
  }

  /** Số NGƯỜI khác nhau bắn event này trong các cửa sổ. */
  async countUsersInWindows(params: {
    name: string;
    appEnv: string;
    windows: { from: Date; to?: Date | null }[];
    whereParams?: Record<string, string>;
    now?: Date;
  }): Promise<number> {
    if (!params.windows.length) return 0;

    const rows = await this.model.aggregate<{ count: number }>([
      { $match: { name: params.name, ...this.windowScope(params) } },
      { $group: { _id: '$userId' } },
      { $count: 'count' },
    ]);

    return rows[0]?.count ?? 0;
  }

  /** Số LƯỢT (không phải số người) — dùng cho "số lượng báo lỗi". */
  async countEventsInWindows(params: {
    name: string;
    appEnv: string;
    windows: { from: Date; to?: Date | null }[];
    whereParams?: Record<string, string>;
    now?: Date;
  }): Promise<number> {
    if (!params.windows.length) return 0;

    return this.model.countDocuments({
      name: params.name,
      ...this.windowScope(params),
    } as FilterQuery<UserEvent>);
  }

  /** Số người khác nhau, nhóm theo một `params.*` — một card hoặc một bài. */
  async countUsersByParamInWindows(params: {
    name: string;
    paramKey: string;
    appEnv: string;
    windows: { from: Date; to?: Date | null }[];
    whereParams?: Record<string, string>;
    now?: Date;
  }): Promise<Record<string, number>> {
    if (!params.windows.length) return {};

    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      { $match: { name: params.name, ...this.windowScope(params) } },
      {
        $group: {
          _id: { value: `$params.${params.paramKey}`, userId: '$userId' },
        },
      },
      { $group: { _id: '$_id.value', count: { $sum: 1 } } },
    ]);

    const counts: Record<string, number> = {};
    for (const row of rows) {
      // Cùng luật với countUsersByParam: bản app chưa gửi param này gom vào
      // null và bị bỏ, chứ không được bịa vào một nhóm nào.
      if (!row._id) continue;
      counts[row._id] = row.count;
    }

    return counts;
  }

  /**
   * Thời gian trung bình từ `startEvent` đến `endEvent` trên cùng một đơn vị
   * (card hoặc bài), trong cùng một phiên.
   *
   * Ba chỗ dễ ra số vô nghĩa, và cả ba đều được chặn ở đây:
   *
   *  - **Phải cùng `sessionId`.** Người mở card rồi ba ngày sau mới quay lại
   *    học tiếp sẽ cho một khoảng 3 ngày; nhóm theo phiên thì lần đó rơi vào
   *    hai phiên khác nhau và cặp không khớp bị loại.
   *  - **Phải có cả hai đầu.** `$min` của một nhóm chỉ có event mở sẽ bằng
   *    `$max`, cho ra 0 giây và kéo trung bình xuống — đúng những người bỏ dở
   *    lại thành người đọc nhanh nhất.
   *  - **Chặn trần.** App bị đưa xuống nền vẫn giữ nguyên phiên, nên phải cắt
   *    những khoảng dài bất thường thay vì để một cái đuôi vài tiếng định đoạt
   *    số trung bình.
   */
  async averageSpanSeconds(params: {
    startEvent: string;
    endEvent: string;
    groupParam: string;
    appEnv: string;
    windows: { from: Date; to?: Date | null }[];
    whereParams?: Record<string, string>;
    capSeconds: number;
    now?: Date;
  }): Promise<number | null> {
    if (!params.windows.length) return null;

    const rows = await this.model.aggregate<{ avg: number; pairs: number }>([
      {
        $match: {
          name: { $in: [params.startEvent, params.endEvent] },
          ...this.windowScope(params),
        },
      },
      {
        $group: {
          _id: {
            userId: '$userId',
            sessionId: '$sessionId',
            unit: `$params.${params.groupParam}`,
          },
          startAt: {
            $min: {
              $cond: [{ $eq: ['$name', params.startEvent] }, '$clientTs', null],
            },
          },
          endAt: {
            $max: {
              $cond: [{ $eq: ['$name', params.endEvent] }, '$clientTs', null],
            },
          },
        },
      },
      {
        $match: {
          '_id.unit': { $nin: [null, ''] },
          startAt: { $ne: null },
          endAt: { $ne: null },
        },
      },
      {
        $addFields: {
          seconds: {
            $divide: [{ $subtract: ['$endAt', '$startAt'] }, 1000],
          },
        },
      },
      { $match: { seconds: { $gt: 0, $lte: params.capSeconds } } },
      { $group: { _id: null, avg: { $avg: '$seconds' }, pairs: { $sum: 1 } } },
    ]);

    const row = rows[0];
    if (!row?.pairs) return null;

    return Math.round(row.avg * 10) / 10;
  }
}
