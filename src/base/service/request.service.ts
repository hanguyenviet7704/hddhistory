import { Inject, Injectable, Scope } from '@nestjs/common';
import { REQUEST } from '@nestjs/core';
import { Request } from 'express';

import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

interface AuthenticatedRequest extends Request {
  user?: IUser;
  headers: any;
}

@Injectable({ scope: Scope.REQUEST })
export class RequestService {
  constructor(
    @Inject(REQUEST) private readonly request: AuthenticatedRequest,
  ) {}

  get user() {
    return this.request.user;
  }

  get headers() {
    return this.request.headers;
  }
}
