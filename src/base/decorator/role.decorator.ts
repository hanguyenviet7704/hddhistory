import { SetMetadata } from '@nestjs/common';

/**
 * Decorator để gán role cho route handler
 *
 * Ví dụ:
 * @Roles('admin')  // chỉ admin mới được truy cập
 * @Roles('admin', 'super-admin') // nhiều role được truy cập
 */
export const Roles = (...roles: string[]) => SetMetadata('roles', roles);
