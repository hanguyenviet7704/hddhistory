import { Body, Controller, Get, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';
import { RequestService } from '@base/service/request.service';

import {
  CreateNotificationCampaignDto,
  GetNotificationCampaignListDto,
  PreviewNotificationCampaignDto,
  UpdateNotificationCampaignDto,
} from './dto/notification-campaign.dto';
import {
  GetNotificationLogDto,
  GetNotificationSummaryDto,
} from './dto/notification-log.dto';
import {
  ImportNotificationTemplateDto,
  SendTestNotificationDto,
  UpdateNotificationTemplateDto,
} from './dto/notification-template.dto';
import { NotificationCampaignService } from './notification-campaign.service';
import { NotificationDispatchService } from './notification-dispatch.service';
import { NotificationLogService } from './notification-log.service';
import { NotificationTemplateService } from './notification-template.service';
import { NotificationType } from './notification.enum';
import { NotificationScheduler } from './notification.scheduler';

/**
 * Admin surface for the scheduled notifications: the content editor
 * (list / update / import / export), the delivery monitor, and a manual test send.
 *
 * Everything here is behind [AuthGuard] — none of it is called by the app.
 */
@ApiTags('NOTIFICATIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'notifications', version: '1' })
export class NotificationController {
  constructor(
    private readonly templateService: NotificationTemplateService,
    private readonly logService: NotificationLogService,
    private readonly dispatchService: NotificationDispatchService,
    private readonly scheduler: NotificationScheduler,
    private readonly campaignService: NotificationCampaignService,
    private readonly requestService: RequestService,
  ) {}

  // ------------------------------------------------------- manual campaigns
  //
  // `campaigns/preview` is declared before `campaigns/:id` so Nest does not
  // read "preview" as an id — same ordering rule as the statistics routes in
  // the feedback controller.

  @Get('campaigns')
  listCampaigns(@Query() dto: GetNotificationCampaignListDto) {
    return this.campaignService.list(dto.appEnv);
  }

  @Post('campaigns/preview')
  previewCampaign(@Body() dto: PreviewNotificationCampaignDto) {
    return this.campaignService.preview(dto.segmentIds);
  }

  @Post('campaigns')
  createCampaign(@Body() dto: CreateNotificationCampaignDto) {
    // The operator is resolved HERE, not in the service: a controller may be
    // request-scoped, whereas the campaign service is reached from the @Cron and
    // must stay a singleton.
    return this.campaignService.create(dto, this.requestService.user);
  }

  @Get('campaigns/:id')
  getCampaign(@Param('id') id: string) {
    return this.campaignService.findOne(id);
  }

  @Put('campaigns/:id')
  updateCampaign(
    @Param('id') id: string,
    @Body() dto: UpdateNotificationCampaignDto,
  ) {
    return this.campaignService.update(id, dto);
  }

  @Post('campaigns/:id/queue')
  queueCampaign(@Param('id') id: string) {
    return this.campaignService.queue(id);
  }

  @Post('campaigns/:id/cancel')
  cancelCampaign(@Param('id') id: string) {
    return this.campaignService.cancel(id);
  }

  @Get('campaigns/:id/sends')
  campaignSends(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('take') take?: string,
  ) {
    return this.campaignService.sends(
      id,
      Number(page) > 0 ? Number(page) : 1,
      Number(take) > 0 ? Math.min(Number(take), 100) : 20,
    );
  }

  @Get('templates')
  findTemplates() {
    return this.templateService.findAll();
  }

  @Put('templates/:type')
  updateTemplate(
    @Param('type') type: NotificationType,
    @Body() dto: UpdateNotificationTemplateDto,
  ) {
    return this.templateService.update(type, dto);
  }

  /** Same shape as `GET templates/export`, so a round trip is lossless. */
  @Post('templates/import')
  importTemplates(@Body() dto: ImportNotificationTemplateDto) {
    return this.templateService.import(dto);
  }

  @Get('templates/export')
  exportTemplates() {
    return this.templateService.export();
  }

  @Get('logs')
  findLogs(@Query() dto: GetNotificationLogDto) {
    return this.logService.findAll(dto);
  }

  /**
   * Whether the cron is alive, and what it last did.
   *
   * Exists because "no notification arrived" had four indistinguishable causes
   * and telling them apart meant reading the container log. Read the timestamps
   * together: no `lastTickAt` means the cron never fired; a fresh `lastTickAt`
   * with no `lastDueAt` means nothing was scheduled for now; `lastDueAt` without
   * `lastSentAt` means something was due and every candidate was filtered out
   * (`notification_logs` then has the per-user reason); `lastError` means the
   * tick threw and the message is the answer.
   */
  @Get('scheduler-status')
  schedulerStatus() {
    return this.scheduler.getStatus();
  }

  @Get('logs/summary')
  logSummary(@Query() dto: GetNotificationSummaryDto) {
    return this.logService.summary(dto);
  }

  /**
   * Fires one notification at one user right now, ignoring the schedule, the
   * trigger condition and the daily caps — the only way to check wording and
   * deep links on a real device without waiting for 21:00.
   */
  @Post('test-send')
  sendTest(@Body() dto: SendTestNotificationDto) {
    return this.dispatchService.sendTest(dto.type, dto.userId, dto.variantKey);
  }
}
