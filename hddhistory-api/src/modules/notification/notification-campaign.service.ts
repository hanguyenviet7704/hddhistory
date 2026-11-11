import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';

import { FirebaseService } from '@base/config/firebase';
import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { DEFAULT_APP_ENV } from 'src/modules/analytics/constant/dashboard.constant';
import { UserEventRepository } from 'src/modules/analytics/repository/user-event.repository';
import { sanitizeDeeplinkParams } from 'src/modules/deeplink/deeplink.catalog';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { SegmentMemberFilterService } from '../segment/segment-member-filter.service';
import { CAMPAIGN_NOTI_TYPE } from './constant/campaign-deeplink.constant';
import {
  NOTI_TAP_CAMPAIGN_PARAM,
  NOTI_TAP_EVENT,
} from './constant/noti-tap.constant';
import {
  CreateNotificationCampaignDto,
  UpdateNotificationCampaignDto,
} from './dto/notification-campaign.dto';
import {
  CAMPAIGN_COPY_VARIABLES,
  campaignReaderName,
  renderCampaignCopy,
  unknownCampaignVariables,
} from './notification-campaign-copy.helper';
import { NotificationDispatchService } from './notification-dispatch.service';
import { describeSendFailure } from './notification-failure.helper';
import { normalizeNotificationImageUrl } from './notification-image.helper';
import {
  NotificationCampaignSendMode,
  NotificationCampaignStatus,
  NotificationLogStatus,
} from './notification.enum';
import { NotificationCampaignSendRepository } from './repository/notification-campaign-send.repository';
import { NotificationCampaignRepository } from './repository/notification-campaign.repository';

/** One candidate, projected to what a send needs. */
interface Candidate {
  _id: any;
  name?: string;
  language?: string;
  timezone?: string;
  devices?: { pushToken?: string; pushEnabled?: boolean }[];
}

@Injectable()
export class NotificationCampaignService {
  private readonly logger = new Logger(NotificationCampaignService.name);

  /**
   * Users handled per cron tick.
   *
   * Small on purpose: the tick also runs the five scheduled types, and a
   * campaign that hogged it would delay those. 300 users ≈ one FCM multicast per
   * 500 tokens, so a 10k audience drains in about half an hour — acceptable for
   * a manual push, and every batch is durably recorded so nothing restarts.
   */
  private static readonly BATCH_SIZE = 300;

  /** Long enough to outlive one batch, short enough that a dead pod frees it. */
  private static readonly LEASE_MS = 2 * 60 * 1000;

  /**
   * Ceiling on campaigns touched in one tick, so a board full of scheduled sends
   * cannot stretch the tick without bound.
   *
   * Generous rather than tight: a campaign with nothing to do costs a date
   * comparison or one sweep of the (per-minute cached) zone clocks, so the real
   * cost is however many are genuinely sending, and each of those is capped by
   * [BATCH_SIZE]. Anything past the ceiling is picked up 60 seconds later.
   */
  private static readonly MAX_CAMPAIGNS_PER_TICK = 20;

  /**
   * How far back the click query looks. `user_events` self-destructs after 90
   * days, so a wider window only costs index pages and still returns nothing —
   * this is the ceiling, and [[list]] narrows it to the oldest campaign shown.
   */
  private static readonly CLICK_RETENTION_DAYS = 90;

  constructor(
    private readonly campaignRepository: NotificationCampaignRepository,
    private readonly sendRepository: NotificationCampaignSendRepository,
    private readonly userRepository: UserRepository,
    private readonly segmentFilter: SegmentMemberFilterService,
    private readonly dispatchService: NotificationDispatchService,
    private readonly firebaseService: FirebaseService,
    private readonly userEventRepository: UserEventRepository,
  ) {}

  // NOTE — do NOT inject RequestService (or anything that does) here.
  //
  // `NotificationScheduler` injects this service to run campaigns from its
  // @Cron. RequestService is Scope.REQUEST, and Nest bubbles that scope UP the
  // graph: the scheduler would become request-scoped and its @Cron would never
  // be registered, silently stopping every notification with no error and a
  // green build. The acting operator is passed in from the controller instead.

  // --------------------------------------------------------------- admin CRUD

  /**
   * Every campaign, newest first, each one carrying how many taps its push got.
   *
   * ## Where the click number comes from, and what it is worth
   *
   * Sends are this API's own bookkeeping (`notification_campaign_sends`);
   * clicks are the app's `noti_tap` events in `user_events`, joined to a
   * campaign by the `campaign_id` the dispatcher puts in the push payload and
   * the app echoes back. Unlike the type-level count on the monitoring cards,
   * this one IS attributed to the exact send — a campaign id is unique, so a tap
   * can only belong to the campaign that caused it, whenever it happened.
   *
   * What still limits it:
   * - `appEnv` scopes the taps but not the sends. Sends live in this database
   *   and carry no environment at all, so a campaign fired at production users
   *   read with `appEnv=dev` shows its real send count beside zero clicks.
   * - Only app builds from 2026-08-25 send `campaign_id`. An older reader's tap
   *   lands in the type-level `campaign` bucket with no id, so it is missing
   *   here — the number is a floor, not a total.
   * - `user_events` self-destructs after 90 days: a campaign older than that
   *   reads zero however many people tapped it at the time.
   *
   * `clicks` counts taps and `clickedUsers` counts people — reopening a push
   * three times is three clicks and one person. The CTR the screen shows is
   * built on the people number so it cannot exceed 100%.
   */
  async list(appEnv: string = DEFAULT_APP_ENV) {
    const campaigns = await this.campaignRepository.findAllNewestFirst();
    if (campaigns.length === 0) return [];

    const [clicks, clickers] = await this.countClicks(campaigns, appEnv);

    return campaigns.map(campaign => ({
      ...campaign,
      clicks: clicks[String(campaign._id)] ?? 0,
      clickedUsers: clickers[String(campaign._id)] ?? 0,
    }));
  }

  /**
   * Taps and distinct tappers per campaign id, in two aggregations over one
   * window rather than one pair per campaign — the list shows up to 200 rows and
   * a query each would be 400 round trips for one screen.
   *
   * The window starts at the oldest campaign on the list (a tap cannot precede
   * the push that caused it) and is floored at the event retention, so a
   * long-lived board does not widen the scan for rows that can only read zero.
   */
  private async countClicks(
    campaigns: { _id: any; startedAt?: Date; createdAt?: Date }[],
    appEnv: string,
  ) {
    const now = new Date();
    const retentionFloor = new Date(
      now.getTime() -
        NotificationCampaignService.CLICK_RETENTION_DAYS * 24 * 60 * 60 * 1000,
    );
    const oldest = campaigns.reduce((earliest, campaign) => {
      const at = campaign.startedAt ?? campaign.createdAt;
      return at && at < earliest ? at : earliest;
    }, now);
    const from = oldest > retentionFloor ? oldest : retentionFloor;

    const params = {
      name: NOTI_TAP_EVENT,
      paramKey: NOTI_TAP_CAMPAIGN_PARAM,
      appEnv,
      from,
      to: now,
    };
    return Promise.all([
      this.userEventRepository.countEventsByParam(params),
      this.userEventRepository.countUsersByParam(params),
    ]);
  }

  async findOne(id: string) {
    const campaign = await this.campaignRepository.findById(id);
    if (!campaign) throw new NotFoundException('Campaign not found');
    return campaign;
  }

  async create(dto: CreateNotificationCampaignDto, actor?: IUserMeta) {
    this.assertCopies(dto);
    return this.campaignRepository.create({
      name: dto.name.trim(),
      copies: this.toCopyMap(dto),
      imageUrl: normalizeNotificationImageUrl(dto.imageUrl),
      deeplink: dto.deeplink,
      deeplinkParams: sanitizeDeeplinkParams(dto.deeplink, dto.deeplinkParams),
      segmentIds: (dto.segmentIds ?? []).map(id => id.trim()).filter(Boolean),
      sendMode: dto.sendMode,
      localHour: dto.localHour ?? 9,
      localMinute: dto.localMinute ?? 0,
      scheduledDate: dto.scheduledDate ?? null,
      status: NotificationCampaignStatus.DRAFT,
      // `createdBy` comes from AbstractRepository.create's second argument —
      // AbstractDocument already owns that field as IUserMeta.
    } as any, actor);
  }

  /** Only a draft is editable: a queued campaign may already be half-sent. */
  async update(id: string, dto: UpdateNotificationCampaignDto) {
    const campaign = await this.findOne(id);
    if (campaign.status !== NotificationCampaignStatus.DRAFT) {
      throw new BadRequestException(
        'Only a draft campaign can be edited — its wording may already be on phones.',
      );
    }
    if (dto.copies) this.assertCopies(dto as CreateNotificationCampaignDto);

    const set: Record<string, unknown> = {};
    if (dto.name !== undefined) set.name = dto.name.trim();
    if (dto.copies) set.copies = this.toCopyMap(dto as CreateNotificationCampaignDto);
    // Chuỗi rỗng là cách người vận hành xoá ảnh, nên `undefined` (không gửi
    // field) và `''` (bấm Xoá ảnh) phải là hai chuyện khác nhau ở đây.
    if (dto.imageUrl !== undefined) {
      set.imageUrl = normalizeNotificationImageUrl(dto.imageUrl);
    }
    if (dto.deeplink !== undefined) set.deeplink = dto.deeplink;
    // Đổi đích cũng phải lọc lại, kể cả khi client không gửi `deeplinkParams`:
    // `variant` của paywall còn sót lại sau khi chuyển sang `home` là một khoá
    // vô nghĩa đi thẳng vào payload push.
    if (dto.deeplink !== undefined || dto.deeplinkParams !== undefined) {
      set.deeplinkParams = sanitizeDeeplinkParams(
        dto.deeplink ?? campaign.deeplink,
        dto.deeplinkParams ?? campaign.deeplinkParams,
      );
    }
    if (dto.segmentIds !== undefined) {
      set.segmentIds = dto.segmentIds.map(sid => sid.trim()).filter(Boolean);
    }
    if (dto.sendMode !== undefined) set.sendMode = dto.sendMode;
    if (dto.localHour !== undefined) set.localHour = dto.localHour;
    if (dto.localMinute !== undefined) set.localMinute = dto.localMinute;
    if (dto.scheduledDate !== undefined) set.scheduledDate = dto.scheduledDate;

    await this.campaignRepository.patch(id, set);
    return this.findOne(id);
  }

  /**
   * How many push-reachable people the current targeting would hit. The operator
   * sees this before authorising the send.
   */
  async preview(segmentIds: string[] | undefined) {
    const filter = await this.segmentFilter.memberFilterForSegments(segmentIds);
    const reach = await this.userRepository.countPushCandidates(
      filter ?? undefined,
    );
    return { reach, targeted: (segmentIds ?? []).length > 0 };
  }

  /** Hands the campaign to the worker. */
  async queue(id: string) {
    const campaign = await this.findOne(id);
    if (campaign.status !== NotificationCampaignStatus.DRAFT) {
      throw new BadRequestException(`Campaign is already ${campaign.status}`);
    }
    if (!Object.keys(campaign.copies ?? {}).length) {
      throw new BadRequestException('Campaign has no wording');
    }
    if (campaign.sendMode === NotificationCampaignSendMode.LOCAL_HOUR) {
      if (!campaign.scheduledDate) {
        throw new BadRequestException(
          'A local-hour campaign needs the date to send on',
        );
      }
    }

    await this.campaignRepository.patch(id, {
      status: NotificationCampaignStatus.QUEUED,
      startedAt: new Date(),
      finishedAt: null,
      lastError: null,
      cursorUserId: null,
      processedZones: [],
      activeZones: [],
      zoneCursorUserId: null,
      sentCount: 0,
      failedCount: 0,
      skippedCount: 0,
    });
    return this.findOne(id);
  }

  /**
   * Stops a campaign mid-flight. Already-delivered notifications cannot be
   * recalled — this only prevents the rest.
   */
  async cancel(id: string) {
    const campaign = await this.findOne(id);
    if (
      campaign.status === NotificationCampaignStatus.SENT ||
      campaign.status === NotificationCampaignStatus.CANCELLED
    ) {
      throw new BadRequestException(`Campaign is already ${campaign.status}`);
    }
    await this.campaignRepository.patch(id, {
      status: NotificationCampaignStatus.CANCELLED,
      finishedAt: new Date(),
      leaseUntil: null,
    });
    return this.findOne(id);
  }

  async sends(id: string, page = 1, take = 20) {
    const { items, total } = await this.sendRepository.listForCampaign(
      id,
      page,
      take,
    );
    return {
      items,
      currentPage: page,
      itemsPerPage: take,
      totalPages: Math.ceil(total / take),
      totalItems: total,
    };
  }

  // ------------------------------------------------------------------- worker

  /**
   * One slice of work per live campaign, called from the same cron tick as the
   * scheduled types.
   *
   * ## Why this is a loop and not a single claim
   *
   * It used to take exactly one campaign per tick — the oldest unfinished one —
   * and that starved everything behind it. `claimNext` asks only what STATUS a
   * campaign is in, never whether it has anything to do now, and a LOCAL_HOUR
   * campaign stays `sending` from the moment it is queued until its day has
   * ended in the last zone on earth, up to 36 hours later. So one campaign
   * waiting out its day owned the only slot, ticking and doing nothing, while
   * every campaign created after it sat at `queued` and missed its hour
   * outright. That is exactly what happened to the two 2026-09-03 sends.
   *
   * Holding a slot open costs nothing precisely because an idle campaign is
   * cheap to dismiss — a date comparison, or one `Intl` read per zone — so the
   * fix is to keep claiming until nothing is free rather than to make the claim
   * query cleverer.
   *
   * Leases are held for the whole tick and released together at the end: that,
   * plus `claimNext`'s `leaseUntil > now` test, is what stops the loop from
   * handing us the same campaign twice.
   */
  async runDueCampaigns(now = new Date()) {
    const leaseUntil = new Date(
      now.getTime() + NotificationCampaignService.LEASE_MS,
    );
    const leased: Types.ObjectId[] = [];
    let sent = 0;

    try {
      while (leased.length < NotificationCampaignService.MAX_CAMPAIGNS_PER_TICK) {
        const claimed = await this.campaignRepository.claimNext(now, leaseUntil);
        if (!claimed) break;

        const id = claimed._id as Types.ObjectId;
        leased.push(id);
        try {
          sent +=
            claimed.sendMode === NotificationCampaignSendMode.LOCAL_HOUR
              ? await this.stepLocalHour(claimed, now)
              : await this.stepNow(claimed);
        } catch (error: any) {
          // The campaign stays SENDING with the error recorded: a transient
          // Mongo or FCM failure should be retried on the next tick, not turn a
          // half-sent campaign into a dead one an operator has to re-create.
          // Its neighbours in this loop are unaffected.
          this.logger.error(
            `Campaign ${String(id)} step failed: ${error?.message}`,
          );
          await this.campaignRepository.patch(id, {
            lastError: error?.message ?? String(error),
          });
        }
      }
    } finally {
      for (const id of leased) await this.campaignRepository.releaseLease(id);
    }

    return { picked: leased.length, sent };
  }

  /** NOW mode: walk the whole audience by `_id`, one batch per tick. */
  private async stepNow(campaign: any) {
    const filter = await this.segmentFilter.memberFilterForSegments(
      campaign.segmentIds,
    );
    const candidates = (await this.userRepository.findPushCandidatesAfterId(
      campaign.cursorUserId ?? null,
      NotificationCampaignService.BATCH_SIZE,
      filter ?? undefined,
    )) as unknown as Candidate[];

    if (candidates.length === 0) {
      await this.finish(campaign._id);
      return 0;
    }

    const sent = await this.sendToCandidates(campaign, candidates);

    // Cursor advances to the last id LOOKED AT, not the last sent: a skipped
    // user must not be re-examined forever.
    await this.campaignRepository.patch(campaign._id, {
      cursorUserId: candidates[candidates.length - 1]._id,
    });

    // A short page means the audience is exhausted — no extra count query.
    if (candidates.length < NotificationCampaignService.BATCH_SIZE) {
      await this.finish(campaign._id);
    }
    return sent;
  }

  /**
   * LOCAL_HOUR mode: send to the zones where the chosen time has just come round
   * ON the scheduled local day, once each, a page of readers per tick.
   *
   * Both halves of "on that day" are load-bearing and neither used to be there.
   * `scheduledDate` only ever closed the campaign, so the clock test stood alone
   * — and "it is 20:00 somewhere" is true again every 24 hours. A campaign
   * queued for next Tuesday went out tonight, and one still alive past its own
   * midnight went out a second time the next day.
   *
   * Finished when the scheduled day has ended even in the last zone on earth
   * (UTC-12), rather than by bookkeeping which zones have users: the zone list
   * changes as people install the app, and a campaign that waited for a zone
   * nobody lives in would never close.
   */
  private async stepLocalHour(campaign: any, now: Date) {
    if (this.localDayIsOverEverywhere(campaign.scheduledDate, now)) {
      await this.finish(campaign._id);
      return 0;
    }
    // Dismissed before the zone sweep so a campaign scheduled a week out costs
    // one date comparison per tick rather than an `Intl` read per zone — this is
    // what makes holding its slot open for a week free.
    if (this.localDayHasNotStartedAnywhere(campaign.scheduledDate, now)) {
      return 0;
    }

    const processed: string[] = campaign.processedZones ?? [];
    // A zone set already being walked keeps priority over looking for new ones:
    // paging it takes several ticks and the due window is only 15 minutes, so
    // re-deriving the set each tick would abandon whoever had not been reached.
    let active: string[] = campaign.activeZones ?? [];
    let cursor: Types.ObjectId | null = campaign.zoneCursorUserId ?? null;

    if (active.length === 0) {
      const due = await this.dispatchService.zonesDueAt(
        campaign.localHour,
        campaign.localMinute ?? 0,
        now,
        campaign.scheduledDate ?? undefined,
      );
      active = due.filter(zone => !processed.includes(zone));
      if (active.length === 0) return 0;
      cursor = null;
      await this.campaignRepository.patch(campaign._id, {
        activeZones: active,
        zoneCursorUserId: null,
      });
    }

    const filter = await this.segmentFilter.memberFilterForSegments(
      campaign.segmentIds,
    );
    const candidates = (await this.userRepository.findPushCandidatesByTimezones(
      active,
      NotificationCampaignService.BATCH_SIZE,
      filter ?? undefined,
      cursor,
    )) as unknown as Candidate[];

    const sent = await this.sendToCandidates(campaign, candidates);

    // A short page means the zone set is drained — the same "no extra count
    // query" test [[stepNow]] uses. Only then are the zones retired, so nobody
    // is dropped because the window closed mid-walk.
    if (candidates.length < NotificationCampaignService.BATCH_SIZE) {
      await this.campaignRepository.patch(campaign._id, {
        processedZones: [...processed, ...active],
        activeZones: [],
        zoneCursorUserId: null,
      });
    } else {
      await this.campaignRepository.patch(campaign._id, {
        zoneCursorUserId: candidates[candidates.length - 1]._id,
      });
    }
    return sent;
  }

  /**
   * True once `scheduledDate` has finished in every zone.
   *
   * UTC-12 is the last place the day ends, so the campaign closes 12 hours after
   * the date's UTC midnight rolls over — plus a day, because the date itself has
   * to end there first.
   */
  private localDayIsOverEverywhere(scheduledDate: string | null, now: Date) {
    if (!scheduledDate) return true;
    const midnight = new Date(`${scheduledDate}T00:00:00Z`);
    if (isNaN(midnight.getTime())) return true;
    const closesAt = midnight.getTime() + 36 * 60 * 60 * 1000;
    return now.getTime() > closesAt;
  }

  /**
   * True while `scheduledDate` has not begun even in the zone that starts it
   * first.
   *
   * UTC+14 (Kiritimati) opens the day 14 hours before its UTC midnight, which is
   * the mirror of the UTC-12 close above. Purely an optimisation — the per-zone
   * date filter in `zonesDueAt` is what actually keeps an early send from
   * happening — so it is deliberately the loose bound, not a second rule to keep
   * in step with the first.
   */
  private localDayHasNotStartedAnywhere(
    scheduledDate: string | null,
    now: Date,
  ) {
    if (!scheduledDate) return false;
    const midnight = new Date(`${scheduledDate}T00:00:00Z`);
    if (isNaN(midnight.getTime())) return false;
    const opensAt = midnight.getTime() - 14 * 60 * 60 * 1000;
    return now.getTime() < opensAt;
  }

  private async sendToCandidates(campaign: any, candidates: Candidate[]) {
    const campaignId = campaign._id as Types.ObjectId;
    let sent = 0;
    let failed = 0;
    let skipped = 0;

    for (const candidate of candidates) {
      const userId = String(candidate._id);
      try {
        // Claim first: see `claimUser` for why the record precedes the push.
        const claimed = await this.sendRepository.claimUser(campaignId, userId);
        if (!claimed) {
          skipped += 1;
          continue;
        }

        const tokens = (candidate.devices ?? [])
          .filter(device => device.pushEnabled !== false)
          .map(device => (device.pushToken ?? '').trim())
          .filter(Boolean);
        if (tokens.length === 0) {
          skipped += 1;
          await this.sendRepository.finalize(campaignId, userId, {
            status: NotificationLogStatus.SKIPPED,
            reason: 'no live token',
          } as any);
          continue;
        }

        const locale = (candidate.language ?? 'en').toLowerCase().split(/[-_]/)[0];
        const copy = this.copyForLocale(campaign.copies, locale);
        if (!copy) {
          skipped += 1;
          await this.sendRepository.finalize(campaignId, userId, {
            status: NotificationLogStatus.SKIPPED,
            reason: 'no wording for locale',
            locale,
          } as any);
          continue;
        }

        // Campaign KHÔNG đi qua `NotificationDispatchService.render`, nên chỗ
        // này là chỗ duy nhất `{user_name}` được thay. Thiếu nó thì dấu ngoặc
        // nhọn lên thẳng màn hình khoá của người đọc.
        const reader = campaignReaderName(candidate.name, copy.locale);
        const title = renderCampaignCopy(copy.title, reader);
        const body = renderCampaignCopy(copy.body, reader);

        const result = await this.firebaseService.sendToTokens(
          tokens,
          title,
          body,
          {
            // Tham số của đích đi TRƯỚC: `deeplink`, `campaignId` và `type` là
            // khoá điều khiển của lớp thông báo và phải luôn thắng. Bộ này đã
            // được lọc theo danh mục lúc lưu, nên đây là lớp phòng thứ hai chứ
            // không phải lớp duy nhất.
            ...(campaign.deeplinkParams ?? {}),
            deeplink: campaign.deeplink,
            campaignId: String(campaignId),
            // `type` là điều kiện để app bắn `noti_tap`: không có nó thì campaign
            // gửi đi rồi cũng không đếm được ai chạm. Một giá trị chung cho mọi
            // campaign, `campaignId` mới là thứ tách từng cái ra.
            type: CAMPAIGN_NOTI_TYPE,
          },
          campaign.imageUrl,
        );

        const ok = result.successCount > 0;
        if (ok) sent += 1;
        else failed += 1;
        await this.sendRepository.finalize(campaignId, userId, {
          status: ok ? NotificationLogStatus.SENT : NotificationLogStatus.FAILED,
          deviceCount: tokens.length,
          successCount: result.successCount,
          failureCount: result.failureCount,
          locale,
          reason: ok ? null : describeSendFailure(result.failures),
        } as any);
      } catch (error: any) {
        // One reader's failure must not abandon the rest of the batch.
        failed += 1;
        this.logger.error(
          `Campaign ${String(campaignId)} user ${userId} failed: ${error?.message}`,
        );
      }
    }

    await this.campaignRepository.patch(
      campaignId,
      {},
      { sentCount: sent, failedCount: failed, skippedCount: skipped },
    );
    return sent;
  }

  private async finish(id: Types.ObjectId) {
    await this.campaignRepository.patch(id, {
      status: NotificationCampaignStatus.SENT,
      finishedAt: new Date(),
      leaseUntil: null,
    });
  }

  /**
   * Reader's locale, else English, else whatever single wording exists.
   *
   * Trả kèm `locale` CỦA WORDING được chọn, không phải locale của user: từ dự
   * phòng cho `{user_name}` phải theo ngôn ngữ của câu, nên một user `vi` rơi về
   * bản `en` phải nhận "you" chứ không phải "bạn".
   */
  private copyForLocale(
    copies: Record<string, { title: string; body: string }>,
    locale: string,
  ): { locale: string; title: string; body: string } | null {
    if (!copies) return null;

    const direct = copies[locale];
    if (direct?.title && direct?.body) return { locale, ...direct };

    const english = copies.en;
    if (english?.title && english?.body) return { locale: 'en', ...english };

    const entry = Object.entries(copies).find(
      ([, item]) => item?.title && item?.body,
    );
    return entry
      ? { locale: entry[0], title: entry[1].title, body: entry[1].body }
      : null;
  }

  private toCopyMap(dto: CreateNotificationCampaignDto) {
    const map: Record<string, { title: string; body: string }> = {};
    for (const copy of dto.copies ?? []) {
      map[copy.locale.toLowerCase()] = {
        title: copy.title.trim(),
        body: copy.body.trim(),
      };
    }
    return map;
  }

  private assertCopies(dto: CreateNotificationCampaignDto) {
    const copies = dto.copies ?? [];
    if (copies.length === 0) {
      throw new BadRequestException('At least one wording is required');
    }
    // English is the fallback every unmatched locale lands on, so a campaign
    // without it would silently skip readers whose language has no wording.
    if (!copies.some(copy => copy.locale.toLowerCase() === 'en')) {
      throw new BadRequestException(
        'An English wording is required — it is the fallback for every other locale',
      );
    }

    // Biến campaign không điền được thì chặn ở đây, chứ không để nó lên màn hình
    // khoá của người đọc dưới dạng `{course_name}`.
    const unknown = Array.from(
      new Set(
        copies.flatMap(copy => [
          ...unknownCampaignVariables(copy.title),
          ...unknownCampaignVariables(copy.body),
        ]),
      ),
    );
    if (unknown.length) {
      throw new BadRequestException(
        `Campaign chỉ điền được ${CAMPAIGN_COPY_VARIABLES.map(name => `{${name}}`).join(', ')}. ` +
          `Bỏ ${unknown.map(name => `{${name}}`).join(', ')} khỏi nội dung.`,
      );
    }
  }
}
