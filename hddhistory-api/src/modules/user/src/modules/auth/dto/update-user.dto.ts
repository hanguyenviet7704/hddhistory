import { OmitType, PartialType } from '@nestjs/swagger';

import { CreateUserDto } from './create-user.dto';

/**
 * `role` is deliberately NOT updatable here.
 *
 * `PUT /users/:id` is `AuthGuard`-only and checks nothing about ownership, so
 * for as long as the DTO carried `role` any authenticated caller could send
 * `{"role":"ADMIN"}` — at their own id or anyone else's — and hand themselves
 * the role. That was harmless only while nothing read `role`; the community's
 * pin action is the first thing that does, and a permission anybody can grant
 * themselves is not a permission.
 *
 * Nothing legitimate loses anything: the panel never sent `role` on this route
 * (there is no user-management screen), the app only ever reads it, and the
 * grant now goes through `POST community/admin/admins`.
 *
 * The WIDER hole is still open — this route lets any caller edit any other
 * user's record by id. Closing that means an ownership check here plus a real
 * admin guard, across every admin surface at once; see the note on
 * CommunitySanctionController.
 */
export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['role'] as const),
) {}
