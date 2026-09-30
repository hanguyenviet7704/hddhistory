import { IntersectionType } from '@nestjs/swagger';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

/**
 * One page of a room's transcript. Newest first — page 1 is the bottom of the
 * screen, page 2 is the history above it.
 */
export class GetCommunityChatDto extends IntersectionType(PageOptionsDto) {}
