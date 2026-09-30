import { Expose } from 'class-transformer';

export class UserMetaDto {
  @Expose()
  id: string;

  @Expose()
  email: string;

  @Expose()
  name: string;
}
