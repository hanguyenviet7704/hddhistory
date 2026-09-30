import { PartialType } from '@nestjs/swagger';

import { CreateKeypointDto } from './create-keypoint.dto';

export class UpdateKeypointDto extends PartialType(CreateKeypointDto) {}
