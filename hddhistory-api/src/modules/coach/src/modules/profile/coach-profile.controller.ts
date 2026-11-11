import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachProfileService } from './coach-profile.service';

/**
 * Admin's window onto what a reader told the Coach about themselves.
 *
 * Read-only, and deliberately so: these are the reader's own words from the
 * onboarding, and the one place they live is `coach_profiles`. The user record
 * already carries age and gender; everything else — the goal, what is in the
 * way, what they are doing now, how they like to learn, what they do — has no
 * column there, and copying it would give the same fact two homes that drift
 * apart the moment the reader changes an answer (owner, 2026-09-05).
 *
 * The address is NOT part of this: how somebody wants to be spoken to is a
 * setting for the conversation, not information about them ("phần xưng hô đó
 * thì không cần").
 */
@ApiTags('COACH-PROFILES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-profiles', version: '1' })
export class CoachProfileController {
  constructor(private readonly svc: CoachProfileService) {}

  @Get(':userId')
  @ApiOperation({
    summary: "What the reader answered in the Coach onboarding, for the admin's user screen",
  })
  async findForAdmin(@Param('userId') userId: string) {
    const profile = await this.svc.get(userId);

    return {
      onboardedAt: profile.onboardedAt,
      goalText: profile.goalText,
      barrierText: profile.barrierText,
      currentPractice: profile.currentPractice,
      learningStyle: profile.learningStyle,
      occupation: profile.occupation,
      occupationRaw: profile.occupationRaw,
    };
  }
}
