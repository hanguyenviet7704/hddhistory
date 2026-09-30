import { PartialType } from '@nestjs/swagger';

import { CreateCommunityTopicDto } from './create-community-topic.dto';

export class UpdateCommunityTopicDto extends PartialType(
  CreateCommunityTopicDto,
) {}
