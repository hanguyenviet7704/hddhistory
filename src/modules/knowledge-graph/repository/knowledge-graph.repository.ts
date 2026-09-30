import { Injectable } from '@nestjs/common';

import {
  IKgEntityProfile,
  IKgEntitySummary,
  IKgRelatedEntity,
} from '../interface/entity-profile.interface';
import { Neo4jProvider } from '../neo4j/neo4j.provider';
import { normalizeVietnamese } from '../util/normalize-vietnamese.util';

/**
 * Lớp DUY NHẤT trong module được phép chạm Neo4j. Service chỉ gọi qua đây,
 * đúng quy tắc phân lớp controller → service → repository của dự án.
 */
@Injectable()
export class KnowledgeGraphRepository {
  constructor(private readonly neo4j: Neo4jProvider) {}

  /** Tìm thực thể theo tên. Khớp trên trường searchName đã bỏ dấu. */
  async search(query: string, limit: number): Promise<IKgEntitySummary[]> {
    const rows = await this.neo4j.read<{ e: { properties: IKgEntitySummary } }>(
      `
      MATCH (e:Entity)
      WHERE $q = '' OR e.searchName CONTAINS $q
      RETURN e
      ORDER BY size(e.name), e.name
      LIMIT toInteger($limit)
      `,
      { q: normalizeVietnamese(query ?? ''), limit },
    );
    return rows.map((row) => this.toSummary(row.e.properties));
  }

  /**
   * Hồ sơ đầy đủ của một thực thể. Gom mọi thứ trong MỘT truy vấn thay vì
   * năm truy vấn rời: các nhánh đều xuất phát từ cùng một nút nên gộp lại
   * tránh năm vòng đi-về tới Neo4j cho mỗi lần xem hồ sơ.
   */
  async findProfile(id: string): Promise<IKgEntityProfile | null> {
    const rows = await this.neo4j.read<any>(
      `
      MATCH (e:Entity {id: $id})
      OPTIONAL MATCH (e)-[r:RELATION]->(target:Entity)
      WITH e, collect(DISTINCT {relation: r.type, entity: target}) AS outgoing
      OPTIONAL MATCH (source:Entity)-[r2:RELATION]->(e)
      WITH e, outgoing,
           collect(DISTINCT {relation: r2.type, entity: source}) AS incoming
      OPTIONAL MATCH (e)-[:IN_PERIOD]->(p:Period)
      OPTIONAL MATCH (peer:Entity)-[:IN_PERIOD]->(p)
      WHERE peer.id <> e.id
      WITH e, outgoing, incoming, p, collect(DISTINCT peer) AS samePeriod
      OPTIONAL MATCH (e)-[:CITED_BY]->(s:Source)
      RETURN e, p, outgoing, incoming, samePeriod,
             collect(DISTINCT s) AS sources
      `,
      { id },
    );

    if (rows.length === 0) return null;
    const row = rows[0];

    return {
      ...this.toSummary(row.e.properties),
      note: row.e.properties.note || undefined,
      period: row.p ? row.p.properties : undefined,
      // Cypher trả về một phần tử rỗng khi OPTIONAL MATCH không khớp gì,
      // nên phải lọc bỏ trước khi ánh xạ.
      outgoing: (row.outgoing ?? [])
        .filter((item: any) => item?.entity)
        .map((item: any) => ({
          relation: item.relation,
          entity: this.toSummary(item.entity.properties),
        })),
      incoming: (row.incoming ?? [])
        .filter((item: any) => item?.entity)
        .map((item: any) => ({
          relation: item.relation,
          entity: this.toSummary(item.entity.properties),
        })),
      samePeriod: (row.samePeriod ?? []).map((node: any) =>
        this.toSummary(node.properties),
      ),
      sources: (row.sources ?? []).map((node: any) => node.properties),
    };
  }

  /** Thực thể tồn tại hay không — dùng để phân biệt 404 với "không có quan hệ". */
  async exists(id: string): Promise<boolean> {
    const rows = await this.neo4j.read<{ found: boolean }>(
      'MATCH (e:Entity {id: $id}) RETURN true AS found LIMIT 1',
      { id },
    );
    return rows.length > 0;
  }

  /**
   * Thực thể liên quan trong bán kính maxHops bước, kèm khoảng cách và các
   * loại quan hệ trên đường đi ngắn nhất.
   *
   * Dùng đường đi VÔ HƯỚNG có chủ đích: trên đồ thị lịch sử, "Ngô Quyền lãnh
   * đạo trận Bạch Đằng" và "trận Bạch Đằng được Ngô Quyền lãnh đạo" là cùng
   * một mối liên quan với người tra cứu, nên chiều mũi tên không nên chặn kết
   * quả. maxHops được nội suy thẳng vào chuỗi truy vấn vì Cypher không cho
   * tham số hoá độ dài đường đi — an toàn vì DTO đã ràng buộc là số nguyên 1–3.
   */
  async findRelated(
    id: string,
    maxHops: number,
    limit: number,
  ): Promise<IKgRelatedEntity[]> {
    const hops = Math.min(Math.max(Math.trunc(maxHops), 1), 3);
    const rows = await this.neo4j.read<any>(
      `
      MATCH path = shortestPath(
        (e:Entity {id: $id})-[:RELATION*1..${hops}]-(other:Entity)
      )
      WHERE other.id <> $id
      RETURN other,
             length(path) AS hops,
             [rel IN relationships(path) | rel.type] AS via
      ORDER BY hops, other.name
      LIMIT toInteger($limit)
      `,
      { id, limit },
    );

    return rows.map((row) => ({
      ...this.toSummary(row.other.properties),
      // Số nguyên từ Neo4j về dưới dạng đối tượng {low, high}; toNumber() có
      // sẵn trên đó, còn hops nhỏ nên không lo tràn số.
      hops:
        typeof row.hops === 'number' ? row.hops : Number(row.hops?.low ?? 0),
      via: row.via ?? [],
    }));
  }

  private toSummary(properties: any): IKgEntitySummary {
    return {
      id: properties.id,
      type: properties.type,
      name: properties.name,
      description: properties.description || undefined,
    };
  }
}
