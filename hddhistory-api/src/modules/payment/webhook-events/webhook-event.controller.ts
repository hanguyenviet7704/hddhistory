import { Body, Controller, Headers, Post } from '@nestjs/common';
import { ApiHeader, ApiTags } from '@nestjs/swagger';

import { WebhookEventService } from './webhook-event.service';

@ApiTags('PAYMENT-WEBHOOKS')
@Controller({ path: 'payment/webhook-events', version: '1' })
export class WebhookEventController {
  constructor(private readonly svc: WebhookEventService) {}

  @Post()
  @ApiHeader({ name: 'authorization', required: false })
  create(@Headers('authorization') authorization: string, @Body() dto: any) {
    return this.svc.handle(dto, { authorization });
  }
}
