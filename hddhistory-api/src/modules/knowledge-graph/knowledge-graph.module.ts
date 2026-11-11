import { forwardRef, Module } from '@nestjs/common';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { KnowledgeGraphController } from './knowledge-graph.controller';
import { KnowledgeGraphService } from './knowledge-graph.service';
import { Neo4jProvider } from './neo4j/neo4j.provider';
import { KnowledgeGraphRepository } from './repository/knowledge-graph.repository';

/**
 * Đồ thị tri thức lịch sử.
 *
 * Khác các module còn lại ở chỗ dữ liệu không nằm trên MongoDB hay MySQL mà
 * trên Neo4j: nghiệp vụ ở đây toàn là truy vấn duyệt quan hệ nhiều bước, loại
 * truy vấn mà CSDL tài liệu và CSDL quan hệ đều phải nối bảng lồng nhau với
 * chi phí tăng theo cấp số nhân theo số bước.
 *
 * Nạp dữ liệu: `npm run seed:knowledge-graph`.
 */
@Module({
  imports: [forwardRef(() => AuthModule), LoggerModule],
  controllers: [KnowledgeGraphController],
  providers: [
    ConfigurationProvider,
    Neo4jProvider,
    KnowledgeGraphRepository,
    KnowledgeGraphService,
  ],
  exports: [KnowledgeGraphService, KnowledgeGraphRepository],
})
export class KnowledgeGraphModule {}
