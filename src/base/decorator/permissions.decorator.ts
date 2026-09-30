import { SetMetadata } from '@nestjs/common';

/**
 * Decorator để gán permission cho route handler
 *
 * Ví dụ:
 * @Permissions('user:read')
 * @Permissions('user:read', 'chat:create')
 */
export const Permissions = (...permissions: string[]) =>
  SetMetadata('permissions', permissions);
