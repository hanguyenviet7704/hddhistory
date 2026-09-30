import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { Types } from 'mongoose';

import {
  GetSessionEventsDto,
  GetUserSessionsDto,
  GetUserSummaryDto,
} from './dto/get-user-analytics.dto';
import { IngestEventsDto, TrackEventDto } from './dto/ingest-events.dto';
import { UserEventKind } from './enum/analytics.enum';
import { IUserEvent } from './interface/user-event.interface';
import { UserEventRepository } from './repository/user-event.repository';

// Params are a free-form bag from the client; cap what one event can carry so a
// runaway payload can't bloat the collection. Oversized bags lose their biggest
// keys and get flagged — we keep the event, never drop it.
const MAX_PARAMS_BYTES = 8 * 1024;

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(private readonly userEventRepository: UserEventRepository) {}

  async ingest(userId: string, dto: IngestEventsDto) {
    if (!userId) throw new BadRequestException('Missing user');

    const docs = (dto.events ?? [])
      .map((event) => this.toDocument(userId, dto, event))
      .filter(Boolean);

    if (!docs.length) return { accepted: 0 };

    const accepted = await this.userEventRepository.insertManyEvents(docs);
    return { accepted };
  }

  async getSummary(userId: string, dto: GetUserSummaryDto) {
    this.assertObjectId(userId);

    return this.userEventRepository.aggregateSummary(
      {
        userId,
        from: this.toDate(dto.from),
        to: this.toDate(dto.to),
        appEnv: dto.appEnv,
      },
      dto.funnelPrefix?.trim() || 'obd_',
    );
  }

  async getSessions(userId: string, dto: GetUserSessionsDto) {
    this.assertObjectId(userId);

    const limit = dto.limit ?? 100;
    const items = await this.userEventRepository.aggregateSessions(
      {
        userId,
        from: this.toDate(dto.from),
        to: this.toDate(dto.to),
        appEnv: dto.appEnv,
      },
      limit,
    );

    // Signals the admin table to suggest narrowing the range instead of
    // pretending this is the whole history.
    return { items, truncated: items.length >= limit };
  }

  async getSessionEvents(userId: string, dto: GetSessionEventsDto) {
    this.assertObjectId(userId);

    const limit = dto.limit ?? 50;
    const items = await this.userEventRepository.findSessionEvents({
      userId,
      sessionId: dto.sessionId,
      namePrefix: dto.namePrefix?.trim() || undefined,
      kind: dto.kind,
      cursor: this.toDate(dto.cursor),
      limit,
    });

    const nextCursor =
      items.length === limit ? items[items.length - 1]?.clientTs : null;

    return { items, nextCursor };
  }

  private assertObjectId(userId: string) {
    if (!Types.ObjectId.isValid(userId)) {
      throw new BadRequestException('Invalid userId');
    }
  }

  private toDate(value?: string): Date | undefined {
    if (!value) return undefined;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? undefined : date;
  }

  private toDocument(
    userId: string,
    dto: IngestEventsDto,
    event: TrackEventDto,
  ): Partial<IUserEvent> | null {
    const name = typeof event?.name === 'string' ? event.name.trim() : '';
    const clientTs = Number(event?.clientTs);

    // A malformed entry is skipped on its own — the rest of the batch still lands.
    if (!name || !Number.isFinite(clientTs) || clientTs <= 0) return null;

    return {
      userId: new Types.ObjectId(userId),
      deviceId: dto.deviceId,
      sessionId: event.sessionId || 'unknown',
      name: name.slice(0, 150),
      kind:
        event.kind === UserEventKind.SCREEN
          ? UserEventKind.SCREEN
          : UserEventKind.EVENT,
      params: this.capParams(event.params),
      clientTs: new Date(clientTs),
      serverTs: new Date(),
      appEnv: dto.appEnv,
      appVersion: dto.appVersion,
      platform: dto.platform,
    };
  }

  private capParams(params?: Record<string, any>): Record<string, any> {
    if (!params || typeof params !== 'object') return {};

    let current: Record<string, any> = { ...params };
    let size = this.byteLength(current);
    if (size <= MAX_PARAMS_BYTES) return current;

    // Drop the biggest key until it fits. Beats truncating blindly: the small
    // ids (course_id, lesson_id…) that make an event readable survive.
    while (size > MAX_PARAMS_BYTES && Object.keys(current).length) {
      const biggest = Object.keys(current).reduce((max, key) =>
        this.byteLength(current[key]) > this.byteLength(current[max])
          ? key
          : max,
      );
      delete current[biggest];
      size = this.byteLength(current);
    }

    current = { ...current, _truncated: true };
    return current;
  }

  private byteLength(value: any): number {
    try {
      return Buffer.byteLength(JSON.stringify(value) ?? '', 'utf8');
    } catch {
      return 0;
    }
  }
}
