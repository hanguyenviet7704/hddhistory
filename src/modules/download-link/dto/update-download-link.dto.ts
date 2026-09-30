import { OmitType, PartialType } from '@nestjs/swagger';

import { CreateDownloadLinkDto } from './create-download-link.dto';

/**
 * `slug` is intentionally not updatable. Once a link has been shared, printed
 * or turned into a QR code, changing its slug silently breaks every copy
 * already in the wild. Retire the link and make a new one instead.
 */
export class UpdateDownloadLinkDto extends PartialType(
  OmitType(CreateDownloadLinkDto, ['slug'] as const),
) {}
