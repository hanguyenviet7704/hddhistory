import { OmitType, PartialType } from '@nestjs/swagger';

import { CreateStudyThemeDto } from './create-study-theme.dto';

// `key` is the immutable route param (`PATCH /study-themes/:key`) — it is
// never accepted in the update body.
export class UpdateStudyThemeDto extends PartialType(
  OmitType(CreateStudyThemeDto, ['key'] as const),
) {}
