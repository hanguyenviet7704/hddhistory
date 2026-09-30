import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { AdminAuditController } from './admin-audit.controller';
import { AdminAuditInterceptor } from './admin-audit.interceptor';
import { AdminAuditService } from './admin-audit.service';
import { AdminAuditRepository } from './repository/admin-audit.repository';
import {
  AdminAuditLog,
  AdminAuditLogSchema,
} from './schema/admin-audit.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AdminAuditLog.name, schema: AdminAuditLogSchema },
    ]),
    // Controller có guard — guard giải phụ thuộc trong module KHAI BÁO route,
    // thiếu dòng này là app crash lúc boot chứ không phải lỗi từng request, và
    // không cổng kiểm tra tĩnh nào thấy được.
    forwardRef(() => AuthModule),
  ],
  controllers: [AdminAuditController],
  providers: [AdminAuditService, AdminAuditRepository, AdminAuditInterceptor],
  // Interceptor được `AppModule` đăng ký làm APP_INTERCEPTOR, nên nó phải ra
  // khỏi module này.
  exports: [AdminAuditService, AdminAuditInterceptor],
})
export class AdminAuditModule {}
