import {
  Injectable,
  OnModuleDestroy,
  ServiceUnavailableException,
} from '@nestjs/common';
import neo4j, { Driver, Session } from 'neo4j-driver';

import { Configuration } from '@base/config/configuration';

/**
 * Giữ một Driver Neo4j dùng chung cho cả tiến trình.
 *
 * Driver được tạo lười (lazy): chỉ khởi tạo ở lần truy vấn đầu tiên, nhờ vậy
 * các môi trường chưa cấu hình Neo4j vẫn boot bình thường — module chỉ hỏng
 * khi thực sự có người gọi endpoint đồ thị, và hỏng bằng lỗi 503 rõ ràng chứ
 * không làm chết cả ứng dụng lúc khởi động.
 */
@Injectable()
export class Neo4jProvider implements OnModuleDestroy {
  private driver: Driver | null = null;

  constructor(private readonly configuration: Configuration) {}

  private getDriver(): Driver {
    if (!this.configuration.isNeo4jConfigured) {
      throw new ServiceUnavailableException(
        'Chưa cấu hình Neo4j: cần đặt NEO4J_URI, NEO4J_USER và NEO4J_PASSWORD',
      );
    }
    if (!this.driver) {
      this.driver = neo4j.driver(
        this.configuration.neo4jUri,
        neo4j.auth.basic(
          this.configuration.neo4jUser,
          this.configuration.neo4jPassword,
        ),
      );
    }
    return this.driver;
  }

  /**
   * Chạy một truy vấn đọc và trả về các bản ghi đã chuyển sang object thường.
   * Session luôn được đóng kể cả khi truy vấn ném lỗi.
   */
  async read<T = Record<string, unknown>>(
    cypher: string,
    params: Record<string, unknown> = {},
  ): Promise<T[]> {
    const session: Session = this.getDriver().session({
      defaultAccessMode: neo4j.session.READ,
    });
    try {
      const result = await session.run(cypher, params);
      return result.records.map((record) => record.toObject() as T);
    } finally {
      await session.close();
    }
  }

  async onModuleDestroy(): Promise<void> {
    if (this.driver) {
      await this.driver.close();
      this.driver = null;
    }
  }
}
