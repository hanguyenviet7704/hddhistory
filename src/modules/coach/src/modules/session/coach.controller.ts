import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachSessionService } from './coach-session.service';
import {
  CoachExplainAgainDto,
  CoachTranscribeDto,
  CoachExitDto,
  CoachTurnDto,
  GetCoachBubbleDto,
  OpenCoachSessionDto,
  SetCoachPersonaDto,
} from './dto/coach-session.dto';

@ApiTags('COACH')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach', version: '1' })
export class CoachController {
  constructor(private readonly svc: CoachSessionService) {}

  @Get('bubble')
  @ApiOperation({
    summary: 'Whether the Coach bubble renders here, and whether it has a dot.',
    description:
      'Deliberately its own small endpoint rather than a field on the Home payload: it is called on every Home entry and must not slow that screen down.',
  })
  getBubble(@Query() dto: GetCoachBubbleDto) {
    return this.svc.getBubble(dto);
  }

  @Post('sessions')
  @ApiOperation({
    summary: 'Open a conversation.',
    description:
      'May answer `{ silent: true, reasonKey }` instead of a session — a door whose guards say to stay quiet is a normal outcome, not an error.',
  })
  open(@Body() dto: OpenCoachSessionDto) {
    return this.svc.open(dto);
  }

  @Post('sessions/:id/turns')
  @ApiOperation({
    summary: 'One turn.',
    description:
      'Returns 410 when the session has expired, which the app answers by opening a new one. Returns 400 when the event does not belong to the current step, rather than guessing at what the reader meant.',
  })
  turn(@Param('id') id: string, @Body() dto: CoachTurnDto) {
    return this.svc.turn(id, dto);
  }

  @Patch('sessions/:id/persona')
  @ApiOperation({
    summary: 'Change the voice, at any step.',
    description:
      'The persona is a header control rather than a step: "đổi được bất cứ lúc nào — kể cả giữa chừng". Remembered for next time; never applied for the reader.',
  })
  setPersona(@Param('id') id: string, @Body() dto: SetCoachPersonaDto) {
    return this.svc.setPersona(id, dto.persona);
  }

  @Post('sessions/:id/close')
  close(@Param('id') id: string) {
    return this.svc.close(id);
  }

  /** Luồng 6 — the plea at ⟨Đóng⟩ was answered. */
  @Post('sessions/:id/exit')
  exit(@Param('id') id: string, @Body() dto: CoachExitDto) {
    return this.svc.recordExit(id, dto.stayed, dto.chips, dto.note);
  }

  @Post('explain-again')
  @ApiOperation({
    summary: 'Somebody asked for a keypoint in simpler words.',
    description:
      'Counts against the CONTENT, weekly — nothing about the reader is written. A keypoint people keep asking to have re-explained is a keypoint that needs rewriting, and that queue is the whole purpose.',
  })
  explainAgain(@Body() dto: CoachExplainAgainDto) {
    return this.svc.explainAgain(dto.keypointId);
  }

  @Post('transcribe')
  @ApiOperation({
    summary: 'Turn a spoken turn into the reader\'s own words.',
    description:
      'The audio is never stored — it exists for the length of this request. The text comes back into the composer for the reader to edit before sending, so a bad transcription is theirs to fix rather than something filed under their name. A failure answers with an empty string rather than an error.',
  })
  transcribe(@Body() dto: CoachTranscribeDto) {
    return this.svc.transcribe(dto);
  }
}
