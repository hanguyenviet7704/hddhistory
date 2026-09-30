import { ApiProperty } from '@nestjs/swagger';

/**
 * Result of a daily warm-up auto-tagging run (shared by preview and apply).
 * Preview reports what *would* change; apply reports what was written. On an
 * idempotent second run every count is 0.
 */
export class DailyWarmUpTaggingResultDto {
  @ApiProperty({
    example: 120,
    description: 'Total lessons examined across the whole catalog.',
  })
  lessonsScanned: number;

  @ApiProperty({
    example: 8,
    description:
      'Exercise folders (LearningItems) whose questions actually change.',
  })
  foldersChanged: number;

  @ApiProperty({
    example: 42,
    description:
      'Questions currently untagged that will be / were set to isDailyWarmUp=true.',
  })
  questionsToTickOn: number;

  @ApiProperty({
    example: 15,
    description:
      'Questions currently tagged that will be / were set to isDailyWarmUp=false.',
  })
  questionsToTickOff: number;
}
