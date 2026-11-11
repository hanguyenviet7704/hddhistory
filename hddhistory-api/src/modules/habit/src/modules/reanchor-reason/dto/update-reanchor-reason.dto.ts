import { PartialType } from '@nestjs/swagger';

import { CreateReanchorReasonDto } from './create-reanchor-reason.dto';

export class UpdateReanchorReasonDto extends PartialType(
  CreateReanchorReasonDto,
) {}
