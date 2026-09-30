import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { StatisticsUsersLearningCoursesOrderBy } from '../enum/user-progress.enum';

export class StatisticsUsersLearningCoursesDto extends PageOptionsDto {
  @ApiPropertyOptional({
    enum: StatisticsUsersLearningCoursesOrderBy,
    default: StatisticsUsersLearningCoursesOrderBy.STARTED_USER_COUNT,
  })
  @IsEnum(StatisticsUsersLearningCoursesOrderBy)
  @IsOptional()
  orderBy?: StatisticsUsersLearningCoursesOrderBy =
    StatisticsUsersLearningCoursesOrderBy.STARTED_USER_COUNT;
}
