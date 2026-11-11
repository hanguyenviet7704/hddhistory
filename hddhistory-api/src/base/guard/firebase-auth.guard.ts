import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { FirebaseService } from '@base/config/firebase';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private readonly firebaseService: FirebaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const token = req.headers.authorization?.split('Bearer ')[1];

    if (!token) throw new UnauthorizedException('Missing Firebase ID token');

    try {
      const decodedToken = await this.firebaseService.verifyToken(token);
      req.user = decodedToken;
      return true;
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (err) {
      console.log(err);

      throw new UnauthorizedException('Invalid Firebase ID token');
    }
  }
}
