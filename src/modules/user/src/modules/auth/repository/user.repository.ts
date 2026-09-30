import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListUserDto } from '../dto/get-user.dto';
import { UserStatus } from '../enum/user.enum';
import { User } from '../schema/user.schema';

@Injectable()
export class UserRepository extends AbstractRepository<User> {
  protected readonly logger = new Logger(UserRepository.name);
  constructor(
    @InjectModel(User.name) model: Model<User>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * How many users match an arbitrary filter.
   *
   * Exists for SEGMENT counting: the segment service compiles its criteria
   * into a Mongo filter (`segment.service.ts`), and this repository is the
   * only layer allowed to run it against the collection. Admin-path only.
   */
  async countByFilter(filter: FilterQuery<User>): Promise<number> {
    return this.model.countDocuments(filter);
  }

  /**
   * Identity for a batch of user ids: name and avatar only.
   *
   * Exists for COMMUNITY reads. A post stores nothing but its authorId, so one
   * page of the feed resolves every author in a single query here — a rename
   * or a new avatar then shows up on old posts instead of staying frozen at
   * whatever was copied in at write time.
   */
  async findIdentitiesByIds(ids: string[]) {
    if (!ids.length) return [];

    return this.model
      .find(
        { _id: { $in: ids.map((id) => new Types.ObjectId(id)) } },
        { name: 1, avatar: 1 },
      )
      .lean();
  }

  /**
   * Identity for a batch of user ids, for ADMIN reads: name, email, anonymous.
   *
   * Separate from `findIdentitiesByIds` rather than a projection added to it:
   * that one feeds the community feed, where an email address next to a post
   * would be a leak. This one is only ever reached through a guarded admin
   * controller, and email is what makes a row in a support ticket findable.
   */
  async findAdminIdentitiesByIds(ids: string[]) {
    const valid = ids.filter((id) => Types.ObjectId.isValid(id));
    if (!valid.length) return [];

    return this.model
      .find(
        { _id: { $in: valid.map((id) => new Types.ObjectId(id)) } },
        { name: 1, email: 1, anonymous: 1 },
      )
      .lean();
  }

  async findOption(getListUserDto: GetListUserDto) {
    const where: FilterQuery<User> = {};

    const { page, take, search, role, status, anonymous, order, orderBy } =
      getListUserDto;

    if (role) {
      where.role = role;
    }

    if (status) {
      where.status = status;
    }

    if (anonymous !== undefined) {
      where.anonymous = anonymous;
    }

    if (search) {
      const searchOr: FilterQuery<User>[] = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
      if (Types.ObjectId.isValid(search)) {
        searchOr.push({ _id: new Types.ObjectId(search) });
      }
      where.$or = searchOr;
    }

    return this.paginateQuery<User>({
      where,
      page,
      take,
      orderBy,
      order,
      projection: {
        password: 0,
        providerData: 0,
        refreshToken: 0,
        onboarding: 0,
      },
    });
  }

  async checkExitsDevice(id: string, deviceId: string) {
    return this.model.exists({ _id: id, 'devices.deviceId': deviceId });
  }

  /**
   * Writes the push fields onto ONE device entry, addressed positionally so a
   * concurrent login on another device can't be clobbered by a read-modify-write
   * of the whole `devices` array.
   */
  async setDevicePush(
    userId: string,
    deviceId: string,
    push: {
      pushToken: string;
      pushEnabled: boolean;
      pushPlatform?: string;
    },
  ) {
    return this.model.updateOne(
      { _id: userId, 'devices.deviceId': deviceId },
      {
        $set: {
          'devices.$.pushToken': push.pushToken,
          'devices.$.pushEnabled': push.pushEnabled,
          'devices.$.pushPlatform': push.pushPlatform ?? null,
          'devices.$.pushUpdatedAt': new Date(),
          updatedAt: new Date(),
        },
      },
    );
  }

  /**
   * Every distinct `timezone` string actually stored on a push-capable user.
   *
   * The dispatcher needs this because zone names have two spellings: ICU
   * enumerates `Asia/Saigon` while phones report `Asia/Ho_Chi_Minh`, so matching
   * the scheduler's canonical name against the stored string directly finds
   * nobody. Reading the spellings that exist is cheaper and more honest than
   * carrying an alias table — see `notification-timezone.helper.ts`.
   */
  async distinctPushCandidateTimezones(): Promise<string[]> {
    const values = await this.model.distinct('timezone', {
      timezone: { $exists: true, $nin: [null, ''] },
      status: UserStatus.ACTIVE,
      devices: {
        $elemMatch: {
          pushToken: { $exists: true, $nin: [null, ''] },
          pushEnabled: { $ne: false },
        },
      },
    });
    return (values as unknown as string[]).filter(Boolean);
  }

  async setStudyReminderTime(
    userId: string,
    time: string | null,
  ): Promise<void> {
    await this.model.updateOne(
      { _id: userId },
      { $set: { studyReminderTime: time } },
    );
  }

  /** Các giờ HH:mm đang có người đặt (≤96 giá trị) — để dispatcher chỉ hỏi zone cho các giờ ấy. */
  async distinctStudyReminderTimes(): Promise<string[]> {
    const values = await this.model.distinct('studyReminderTime', {
      studyReminderTime: { $exists: true, $nin: [null, ''] },
      status: UserStatus.ACTIVE,
    });
    return (values as unknown as string[]).filter(Boolean);
  }

  /**
   * Users who can receive a scheduled notification right now: at least one device
   * with a push token whose in-app switch is on, and a time zone in [timezones].
   *
   * [timezones] must already carry every SPELLING of the due zones (canonical
   * plus whatever devices actually stored) — this compares raw strings, which is
   * what keeps the query indexed.
   *
   * Only the fields the dispatcher needs are projected — this runs every minute,
   * and pulling whole user documents (onboarding answers included) would make it
   * needlessly heavy.
   */
  /** The shared "can actually receive a push" conditions. */
  private pushReachableFilter(): FilterQuery<User> {
    return {
      status: UserStatus.ACTIVE,
      devices: {
        $elemMatch: {
          pushToken: { $exists: true, $nin: [null, ''] },
          pushEnabled: { $ne: false },
        },
      },
    };
  }

  /**
   * How many people a campaign would actually reach — used by the admin's
   * preview before anything is sent.
   *
   * Counts push-REACHABLE members, not segment members: a segment of 5,000 with
   * 900 push tokens sends 900 notifications, and showing the bigger number would
   * misrepresent the blast an operator is about to authorise.
   */
  async countPushCandidates(extraFilter?: FilterQuery<User>): Promise<number> {
    const filter = this.pushReachableFilter();
    return this.model.countDocuments(
      extraFilter ? { $and: [filter, extraFilter] } : filter,
    );
  }

  /**
   * One page of push-reachable users after [afterId], ascending by `_id`.
   *
   * Keyset paging, not `skip`: a campaign walks its audience over many cron
   * ticks, and `skip` would both slow down as the offset grows and shift under
   * any user whose token changed mid-walk, silently skipping people.
   */
  async findPushCandidatesAfterId(
    afterId: Types.ObjectId | null,
    limit: number,
    extraFilter?: FilterQuery<User>,
  ) {
    const conditions: FilterQuery<User>[] = [this.pushReachableFilter()];
    if (afterId) conditions.push({ _id: { $gt: afterId } });
    if (extraFilter) conditions.push(extraFilter);

    return this.model
      .find(
        { $and: conditions },
        { _id: 1, name: 1, language: 1, timezone: 1, devices: 1 },
      )
      .sort({ _id: 1 })
      .limit(limit)
      .lean();
  }

  /**
   * Push-reachable users in the given zones.
   *
   * [extraFilter] narrows the same query instead of filtering the result in
   * memory — it carries segment targeting (see
   * `SegmentService.memberFilterForSegments`), and a segment can exclude most of
   * the base set. Filtering afterwards would still pull `limit` rows of the
   * WRONG people and could return none of the targeted ones.
   *
   * [afterId] pages the zone the same way `findPushCandidatesAfterId` pages the
   * whole audience. It was one unpaged shot of up to 5000 users, which both
   * dropped everyone past that ceiling without a trace and ran a single tick
   * long enough to stall the scheduler behind it.
   */
  async findPushCandidatesByTimezones(
    timezones: string[],
    limit = 5000,
    extraFilter?: FilterQuery<User>,
    afterId: Types.ObjectId | null = null,
  ) {
    const filter: FilterQuery<User> = {
      timezone: { $in: timezones },
      status: UserStatus.ACTIVE,
      devices: {
        $elemMatch: {
          pushToken: { $exists: true, $nin: [null, ''] },
          pushEnabled: { $ne: false },
        },
      },
    };

    const conditions: FilterQuery<User>[] = [filter];
    if (afterId) conditions.push({ _id: { $gt: afterId } });
    if (extraFilter) conditions.push(extraFilter);

    // Ordered by `_id` even when [afterId] is null: the caller pages through a
    // zone over several ticks, and `limit` without a stable order would return
    // an arbitrary window each time — some readers twice, others never.
    return this.model
      .find(
        conditions.length > 1 ? { $and: conditions } : filter,
        { _id: 1, name: 1, language: 1, timezone: 1, devices: 1 },
      )
      .sort({ _id: 1 })
      .limit(limit)
      .lean();
  }

  /**
   * Drops tokens Firebase reported as permanently gone, wherever they sit. Left
   * in place they would be retried on every single tick.
   */
  async pruneDeadPushTokens(tokens: string[]) {
    if (tokens.length === 0) return null;
    return this.model.updateMany(
      { 'devices.pushToken': { $in: tokens } },
      {
        $unset: {
          'devices.$[dead].pushToken': '',
          'devices.$[dead].pushEnabled': '',
        },
      },
      { arrayFilters: [{ 'dead.pushToken': { $in: tokens } }] },
    );
  }

  /**
   * Detaches [pushToken] from every OTHER user holding it.
   *
   * An FCM token belongs to an app INSTALL, not to a person: when a second
   * account signs in on the same phone, Firebase hands out the same token. Left
   * alone, both user documents would carry it and the 14:00 reminder — which
   * embeds `{user_name}` and `{course_name}` — would be delivered under the
   * wrong account.
   */
  async detachPushTokenFromOtherUsers(pushToken: string, exceptUserId: string) {
    return this.model.updateMany(
      { _id: { $ne: exceptUserId }, 'devices.pushToken': pushToken },
      {
        $unset: {
          'devices.$[matched].pushToken': '',
          'devices.$[matched].pushEnabled': '',
        },
      },
      { arrayFilters: [{ 'matched.pushToken': pushToken }] },
    );
  }

  /**
   * Every account this device has ever signed in on, newest sign-in first.
   *
   * More than one is normal rather than exceptional: a guest upgraded by a
   * provider login keeps the device row, and any later forced sign-out mints a
   * fresh guest carrying the same `deviceId`. Callers therefore have to CHOOSE,
   * which is why this returns the list instead of one document.
   *
   * Sorting is deliberately done here in memory. `sort: { 'devices.loginAt': -1 }`
   * looks like it orders by this device's last sign-in, but the path is inside
   * an array: Mongo orders by the largest `loginAt` in the whole `devices` list,
   * so an account that signed in on a DIFFERENT phone an hour ago outranks the
   * one that signed in on this one a minute ago.
   */
  async findAllByDeviceId(deviceId: string) {
    const users = await this.model
      .find(
        { 'devices.deviceId': deviceId },
        { password: 0, providerData: 0, 'devices.refreshToken': 0 },
      )
      .lean();

    const loginAtOnThisDevice = (user: any) =>
      (user.devices ?? [])
        .find((device: any) => device.deviceId === deviceId)
        ?.loginAt?.getTime?.() ?? 0;

    return (users as any[]).sort((left, right) => {
      const diff = loginAtOnThisDevice(right) - loginAtOnThisDevice(left);
      // `_id` breaks ties so two accounts stamped in the same millisecond do not
      // swap places between calls — the caller's answer has to be stable.
      return diff !== 0 ? diff : String(right._id).localeCompare(String(left._id));
    });
  }

  /**
   * Stamp the first-run Confession tour as done.
   *
   * `$setOnInsert`-style guard by filter rather than a plain set: the tour
   * finishing twice (a double tap on the last step, two devices at once) must
   * not move the date, because the date is the only record of when this reader
   * actually met the forum.
   */
  async markCommunityTourSeen(id: string) {
    return this.updateOne(
      { _id: id, communityTourSeenAt: null } as any,
      { communityTourSeenAt: new Date() } as Partial<User>,
    );
  }

  async resetOnboarding(id: string) {
    return this.updateOne(
      { _id: id },
      { isOnboarded: false, onboarding: {} } as Partial<User>,
    );
  }
}
