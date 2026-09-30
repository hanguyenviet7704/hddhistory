import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { SaveOnboardingAnswerDto } from './dto/save-onboarding-answer.dto';
import { OnboardingAnswerService } from './onboarding-answer.service';

@ApiTags('ONBOARDING-ANSWERS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'onboarding-answers', version: '1' })
export class OnboardingAnswerController {
  constructor(private readonly svc: OnboardingAnswerService) {}

  @Post('')
  save(@Body() dto: SaveOnboardingAnswerDto) {
    return this.svc.save(dto);
  }

  @Get('me')
  me() {
    return this.svc.me();
  }
}
