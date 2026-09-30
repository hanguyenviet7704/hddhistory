import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  SetCourseVoiceoverProviderDto,
  UpdateVoiceoverSettingsDto,
} from './dto/voiceover-settings.dto';
import { VoiceoverJobService } from './voiceover-job.service';
import { VoiceoverMergeService } from './voiceover-merge.service';
import { VoiceoverSettingsService } from './voiceover-settings.service';
import { AudioClipBackfillService } from './audio-clip-backfill.service';
import { VoiceoverService } from './voiceover.service';

// None of the generate endpoints takes a body: the narrator is fixed at one
// female voice per language (see `DEFAULT_VOICES`), so there is nothing left for
// a caller to choose. The old `GET /voiceover/voices` picker feed went with it.
@ApiTags('VOICEOVER')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'voiceover', version: '1' })
export class VoiceoverController {
  constructor(
    private readonly voiceoverService: VoiceoverService,
    private readonly voiceoverJobService: VoiceoverJobService,
    private readonly voiceoverMergeService: VoiceoverMergeService,
    private readonly voiceoverSettingsService: VoiceoverSettingsService,
    private readonly audioClipBackfillService: AudioClipBackfillService,
  ) {}

  // Generate (or refresh) voiceover for a single keypoint from its theory
  // content. `?force=true` re-synthesises even unchanged languages.
  @Post('keypoint/:keypointId')
  generateForKeypoint(
    @Param('keypointId') keypointId: string,
    @Query('force') force?: string,
  ) {
    return this.voiceoverService.generateForKeypoint(keypointId, {
      force: force === 'true',
    });
  }

  // Start a background job that generates voiceover for every keypoint of a
  // course. Returns immediately with the job snapshot — the client polls the
  // status endpoint for progress. Idempotent + resumable; a run already in
  // progress for the course is returned as-is (no double-start).
  // `?force=true` re-synthesises even languages whose text and narrator are
  // unchanged. Needed for one repair the hash skip cannot reach on its own: a
  // course whose stored narrator says one thing while its clips are another —
  // reuse compares exactly those two and concludes there is nothing to do.
  @Post('course/:courseId')
  generateForCourse(
    @Param('courseId') courseId: string,
    @Query('force') force?: string,
  ) {
    return this.voiceoverJobService.start(courseId, force === 'true');
  }

  // Read-only coverage report (which keypoints × languages are done / stale /
  // missing / failed) plus the live background-job progress, if any. No
  // synthesis, but it reads the whole course — poll GET /voiceover/job instead.
  @Get('course/:courseId/status')
  async getCourseStatus(@Param('courseId') courseId: string) {
    const [status, job] = await Promise.all([
      this.voiceoverService.getCourseStatus(courseId),
      this.voiceoverJobService.getCourseJob(courseId),
    ]);

    return { ...status, job };
  }

  /**
   * Progress of every dub run in flight — the global one and any per-course
   * ones — and nothing else.
   *
   * This is what a progress poll should hit. The admin's 3-second poll used to
   * call GET /status below, which re-scans every keypoint of every course on
   * each tick; on the same process that was running the dub, the monitoring was
   * competing with the work it was monitoring.
   */
  @Get('job')
  getJobs() {
    return this.voiceoverJobService.getFeed();
  }

  // GLOBAL, read-only coverage report across every course (the admin "Scan"
  // button) plus the live global-job progress, if any. No synthesis, but it
  // scans the whole catalogue — an explicit action, not a poll.
  @Post('backfill-clips')
  @ApiOperation({
    summary:
      'Seed the content-addressed clip store from the audio already on every keypoint. Idempotent; run once per environment before trusting per-tag audio.',
  })
  backfillClips() {
    return this.audioClipBackfillService.run();
  }

  @Get('status')
  async getGlobalStatus() {
    const [status, job] = await Promise.all([
      this.voiceoverService.getGlobalStatus(),
      this.voiceoverJobService.getGlobalJob(),
    ]);

    return { ...status, job };
  }

  // Start a single background job that generates voiceover for every
  // keypoint of every course. `?force=true` regenerates even unchanged
  // languages; otherwise only missing/stale/failed languages are
  // re-synthesised (existing per-keypoint hash-skip). `?resume=true` continues
  // an interrupted run, skipping the courses it had already finished — opt-in,
  // since a plain re-run must re-check courses that may have been edited.
  // Returns immediately with the job snapshot — the client polls GET
  // /voiceover/job for progress. A run already in progress is returned as-is
  // (no double-start).
  @Post('generate-all')
  generateAll(
    @Query('force') force?: string,
    @Query('resume') resume?: string,
  ) {
    return this.voiceoverJobService.startGlobal(
      force === 'true',
      resume === 'true',
    );
  }

  // Backfill: concat the existing per-card clips of every dubbed keypoint
  // into one merged file per language (`audio.merged`). No TTS — pure
  // download + ffmpeg concat + upload. Idempotent via the merge hash;
  // `?force=true` re-concatenates even unchanged languages. Returns
  // immediately with the job snapshot — poll the status endpoint below.
  @Post('merge-all')
  mergeAll(@Query('force') force?: string) {
    return this.voiceoverMergeService.startMergeAll({
      force: force === 'true',
    });
  }

  @Get('merge-all/status')
  getMergeAllStatus() {
    return this.voiceoverMergeService.snapshot();
  }

  // --- Vbee (paid Vietnamese provider) -------------------------------------
  //
  // The narrator IS still fixed per language — these endpoints do not reopen
  // the per-run voice picker that was deliberately removed. They pick the ONE
  // Vietnamese narrator used by every course on Vbee, which has to be settable
  // without a deploy because it is a pricing decision (`creditFactor` 1, 2 or
  // 3) as much as a casting one.

  // Every Vietnamese voice the account may synthesise with, each with its
  // credit factor and a demo clip so a narrator can be chosen by ear.
  @Get('vbee/voices')
  getVbeeVoices() {
    return this.voiceoverSettingsService.listVbeeVoices();
  }

  @Get('settings')
  getSettings() {
    return this.voiceoverSettingsService.getSettings();
  }

  @Put('settings')
  updateSettings(@Body() dto: UpdateVoiceoverSettingsDto) {
    return this.voiceoverSettingsService.updateVbeeVoice(dto.vbeeVoiceCode);
  }

  // Opt one course's Vietnamese in or out of the paid provider. Changes nothing
  // by itself — the next dub of this course is what re-synthesises Vietnamese,
  // because the stored narrator no longer matches.
  @Put('course/:courseId/provider')
  setCourseProvider(
    @Param('courseId') courseId: string,
    @Body() dto: SetCourseVoiceoverProviderDto,
  ) {
    return this.voiceoverService.setCourseViProvider(courseId, dto.provider);
  }

  // What a Vbee dub of this course would cost, in characters and credits,
  // BEFORE anything is spent. Read-only; replays the same per-card reuse rules
  // the dub itself uses, so it is a count and not an average.
  @Get('course/:courseId/estimate')
  estimateCourse(@Param('courseId') courseId: string) {
    return this.voiceoverService.estimateCourseVbee(courseId);
  }
}
