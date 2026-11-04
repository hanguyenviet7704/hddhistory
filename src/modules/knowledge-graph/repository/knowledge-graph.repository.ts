import { Injectable } from '@nestjs/common';

import {
  IKgClaim,
  IKgEntityProfile,
  IKgEntitySummary,
  IKgOverview,
  IKgRelatedEntity,
  IKgRelation,
  IKgSource,
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

  /**
   * Tìm thực thể theo tên HOẶC bí danh (đều đã bỏ dấu), lọc thêm theo loại và
   * thời kỳ. Không có từ khoá thì thành danh sách duyệt theo bộ lọc.
   *
   * Khớp tên đứng trước khớp bí danh: gõ "tran" thì "Nhà Trần" lên trước
   * "Trần Hưng Đạo" (vốn chỉ khớp qua bí danh "Đức Thánh Trần" thì xếp sau).
   */
  async search(
    query: string,
    limit: number,
    filters: { type?: string; periodId?: string } = {},
  ): Promise<IKgEntitySummary[]> {
    const rows = await this.neo4j.read<{ e: { properties: any } }>(
      `
      MATCH (e:Entity)
      WHERE ($type IS NULL OR e.type = $type)
        AND ($periodId IS NULL
             OR EXISTS { (e)-[:IN_PERIOD]->(:Period {id: $periodId}) })
      WITH e,
           CASE
             WHEN $q = '' THEN 0
             WHEN e.searchName STARTS WITH $q THEN 0
             WHEN e.searchName CONTAINS $q THEN 1
             WHEN any(a IN coalesce(e.searchAliases, []) WHERE a CONTAINS $q)
               THEN 2
             ELSE -1
           END AS rank
      WHERE rank >= 0
      RETURN e
      ORDER BY rank, size(e.name), e.name
      LIMIT toInteger($limit)
      `,
      {
        q: normalizeVietnamese(query ?? ''),
        limit,
        type: filters.type ?? null,
        periodId: filters.periodId ?? null,
      },
    );
    return rows.map(row => this.toSummary(row.e.properties));
  }

  /**
   * Toàn cảnh: thời kỳ theo thứ tự (id `p01…p12` đã đúng trình tự thời gian)
   * kèm số thực thể, và quy mô cả đồ thị — mục lục cho trang duyệt.
   */
  async findOverview(): Promise<IKgOverview> {
    const [periods, totals] = await Promise.all([
      this.neo4j.read<any>(
        `
        MATCH (p:Period)
        OPTIONAL MATCH (e:Entity)-[:IN_PERIOD]->(p)
        RETURN p, count(e) AS entityCount
        ORDER BY p.id
        `,
      ),
      this.neo4j.read<any>(
        `
        MATCH (e:Entity)
        WITH count(e) AS entities, collect(e.type) AS types
        OPTIONAL MATCH ()-[r:RELATION]->()
        WITH entities, types, count(r) AS relations
        OPTIONAL MATCH (c:Claim)
        RETURN entities, types, relations, count(c) AS claims
        `,
      ),
    ]);
    const row = totals[0];
    const byType: Record<string, number> = {};
    for (const type of (row?.types ?? []) as string[]) {
      byType[type] = (byType[type] ?? 0) + 1;
    }
    return {
      periods: periods.map((r: any) => ({
        ...r.p.properties,
        entityCount: this.toNumber(r.entityCount),
      })),
      totals: {
        entities: this.toNumber(row?.entities),
        relations: this.toNumber(row?.relations),
        claims: this.toNumber(row?.claims),
        byType,
      },
    };
  }

  /**
   * Hồ sơ đầy đủ của một thực thể. Gom mọi thứ trong MỘT truy vấn thay vì
   * năm truy vấn rời: các nhánh đều xuất phát từ cùng một nút nên gộp lại
   * tránh năm vòng đi-về tới Neo4j cho mỗi lần xem hồ sơ.
   */
  async findProfile(id: string): Promise<IKgEntityProfile | null> {
    // Nguồn của từng quan hệ chỉ được lưu dạng id (`RELATION.sourceIds`).
    // Cả đồ thị chỉ có chục nguồn nên tra bảng nguồn song song rẻ hơn là
    // ghép trong Cypher (pattern comprehension không nhận nút đứng một mình).
    const [rows, sourceRows] = await Promise.all([
      this.neo4j.read<any>(
        `
      MATCH (e:Entity {id: $id})
      OPTIONAL MATCH (e)-[r:RELATION]->(target:Entity)
      WITH e, collect(DISTINCT {
        relation: r.type, note: r.note, entity: target,
        sourceIds: coalesce(r.sourceIds, [])
      }) AS outgoing
      OPTIONAL MATCH (source:Entity)-[r2:RELATION]->(e)
      WITH e, outgoing, collect(DISTINCT {
        relation: r2.type, note: r2.note, entity: source,
        sourceIds: coalesce(r2.sourceIds, [])
      }) AS incoming
      OPTIONAL MATCH (e)-[:IN_PERIOD]->(p:Period)
      OPTIONAL MATCH (peer:Entity)-[:IN_PERIOD]->(p)
      WHERE peer.id <> e.id
      WITH e, outgoing, incoming, p, collect(DISTINCT peer) AS samePeriod
      OPTIONAL MATCH (e)-[:CITED_BY]->(s:Source)
      WITH e, outgoing, incoming, p, samePeriod,
           collect(DISTINCT s) AS sources
      OPTIONAL MATCH (c:Claim)-[:ABOUT]->(e)
      WITH e, outgoing, incoming, p, samePeriod, sources,
           collect(DISTINCT {
             claim: c,
             positions: [(c)-[pos:POSITION]->(ps:Source) |
                         {text: pos.text, order: pos.order, source: ps}]
           }) AS claims
      RETURN e, p, outgoing, incoming, samePeriod, sources, claims
      `,
        { id },
      ),
      this.neo4j.read<any>('MATCH (s:Source) RETURN s'),
    ]);
    const sourceById = new Map<string, IKgSource>(
      sourceRows.map((r: any) => {
        const source = this.toSource(r.s.properties);
        return [source.id, source];
      }),
    );

    if (rows.length === 0) return null;
    const row = rows[0];

    return {
      ...this.toSummary(row.e.properties),
      note: row.e.properties.note || undefined,
      period: row.p ? row.p.properties : undefined,
      // Cypher trả về một phần tử rỗng khi OPTIONAL MATCH không khớp gì,
      // nên phải lọc bỏ trước khi ánh xạ.
      outgoing: this.toRelations(row.outgoing, sourceById),
      incoming: this.toRelations(row.incoming, sourceById),
      samePeriod: (row.samePeriod ?? []).map((node: any) =>
        this.toSummary(node.properties),
      ),
      sources: (row.sources ?? []).map((node: any) =>
        this.toSource(node.properties),
      ),
      claims: this.toClaims(row.claims),
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

    return rows.map(row => ({
      ...this.toSummary(row.other.properties),
      // Số nguyên từ Neo4j về dưới dạng đối tượng {low, high}; toNumber() có
      // sẵn trên đó, còn hops nhỏ nên không lo tràn số.
      hops:
        typeof row.hops === 'number' ? row.hops : Number(row.hops?.low ?? 0),
      via: row.via ?? [],
    }));
  }

  private toSummary(properties: any): IKgEntitySummary {
    const aliases: string[] = properties.aliases ?? [];
    return {
      id: properties.id,
      type: properties.type,
      name: properties.name,
      description: properties.description || undefined,
      aliases: aliases.length ? aliases : undefined,
      date: properties.date || undefined,
    };
  }

  private toSource(properties: any): IKgSource {
    return {
      id: properties.id,
      title: properties.title,
      note: properties.note || undefined,
    };
  }

  private toRelations(
    items: any[] | null,
    sourceById: Map<string, IKgSource>,
  ): IKgRelation[] {
    // Cypher trả về một phần tử rỗng khi OPTIONAL MATCH không khớp gì, nên
    // phải lọc bỏ trước khi ánh xạ.
    return (items ?? [])
      .filter((item: any) => item?.entity)
      .map((item: any) => {
        const sources = ((item.sourceIds ?? []) as string[])
          .map(sourceId => sourceById.get(sourceId))
          .filter((source): source is IKgSource => Boolean(source));
        return {
          relation: item.relation,
          entity: this.toSummary(item.entity.properties),
          note: item.note || undefined,
          sources: sources.length ? sources : undefined,
        };
      });
  }

  private toClaims(items: any[] | null): IKgClaim[] {
    return (items ?? [])
      .filter((item: any) => item?.claim)
      .map((item: any) => ({
        id: item.claim.properties.id,
        description: item.claim.properties.description,
        // Thứ tự lập trường giữ đúng như người soạn viết trong tệp seed.
        positions: [...(item.positions ?? [])]
          .sort(
            (a: any, b: any) => this.toNumber(a.order) - this.toNumber(b.order),
          )
          .map((position: any) => ({
            text: position.text,
            source: this.toSource(position.source.properties),
          })),
      }));
  }

  /** Số nguyên Neo4j về dưới dạng {low, high} hoặc number tuỳ driver. */
  private toNumber(value: any): number {
    if (typeof value === 'number') return value;
    if (value && typeof value.toNumber === 'function') return value.toNumber();
    return Number(value?.low ?? 0);
  }
}
