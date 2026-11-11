/**
 * Nạp đồ thị tri thức lịch sử Việt Nam vào Neo4j để ba endpoint
 * /api/v1/knowledge-graph/... có dữ liệu trả về.
 *
 * Idempotent: dùng MERGE theo id nên chạy lại nhiều lần không nhân đôi dữ
 * liệu; các thuộc tính được ghi đè bằng giá trị trong tệp nguồn, tức tệp
 * nguồn luôn là chân lý (khác các seeder Mongo trong thư mục này — chúng cố
 * ý không ghi đè để giữ chỉnh sửa của admin).
 *
 * Nguồn dữ liệu mặc định là bản chép trong repo này. Bản soạn thảo gốc nằm ở
 * repo knowledge-graph; muốn nạp thẳng từ đó thì truyền --file.
 *
 * Chạy:
 *   npm run seed:knowledge-graph
 *   npm run seed:knowledge-graph -- --file ../knowledge-graph/data/vn_history/vn_history_seed.json
 *   npm run seed:knowledge-graph -- --reset     (xoá sạch đồ thị cũ trước khi nạp)
 *
 * Ngoài hồ sơ và quan hệ, seeder còn nạp những thứ coach lịch sử cần để dẫn
 * nguồn: `Entity.date`, `Entity.aliases` (+ `searchAliases` đã bỏ dấu),
 * `RELATION.sourceIds`, và các nhận định tranh cãi
 * `(:Claim {id, description})-[:ABOUT]->(:Entity)` cùng
 * `(:Claim)-[:POSITION {text, order}]->(:Source)`.
 *
 * Đọc NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD từ env/.env
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import neo4j, { Driver } from 'neo4j-driver';

import { normalizeVietnamese } from '../src/modules/knowledge-graph/util/normalize-vietnamese.util';

interface SeedPeriod {
  id: string;
  name: string;
  start: string;
  end: string;
}
interface SeedSource {
  id: string;
  title: string;
  note?: string;
}
interface SeedEntity {
  id: string;
  type: string;
  name: string;
  aliases?: string[];
  /** Mốc thời gian dạng chữ, vd "1075–1077", "1258, 1285, 1288". */
  date?: string | null;
  description?: string;
  note?: string;
  period_id?: string | null;
  source_ids?: string[];
}
interface SeedRelation {
  head: string;
  relation: string;
  tail: string;
  note?: string;
  source_ids?: string[];
}
interface SeedClaimPosition {
  source_id: string;
  claim: string;
}
interface SeedClaim {
  id: string;
  topic_entity_id: string;
  description: string;
  positions: SeedClaimPosition[];
}
interface SeedFile {
  periods: SeedPeriod[];
  sources: SeedSource[];
  entities: SeedEntity[];
  relations: SeedRelation[];
  claims?: SeedClaim[];
}

const DEFAULT_FILE = path.join(
  __dirname,
  '..',
  'src',
  'modules',
  'knowledge-graph',
  'data',
  'vn_history_seed.json',
);

function parseArgs(): { file: string; reset: boolean } {
  const argv = process.argv.slice(2);
  const fileFlag = argv.indexOf('--file');
  return {
    file: fileFlag >= 0 ? path.resolve(argv[fileFlag + 1]) : DEFAULT_FILE,
    reset: argv.includes('--reset'),
  };
}

async function run(): Promise<void> {
  const { file, reset } = parseArgs();

  const { NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD } = process.env;
  if (!NEO4J_URI || !NEO4J_USER || !NEO4J_PASSWORD) {
    throw new Error(
      'Thiếu cấu hình Neo4j: cần NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD trong env/.env',
    );
  }

  const data: SeedFile = JSON.parse(fs.readFileSync(file, 'utf-8'));
  const claims = data.claims ?? [];
  console.log(
    `Nguồn: ${file}\n` +
      `  ${data.periods.length} thời kỳ, ${data.sources.length} nguồn, ` +
      `${data.entities.length} thực thể, ${data.relations.length} quan hệ, ` +
      `${claims.length} nhận định`,
  );

  const driver: Driver = neo4j.driver(
    NEO4J_URI,
    neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD),
  );
  const session = driver.session();

  try {
    if (reset) {
      await session.run(
        `MATCH (n)
         WHERE n:Entity OR n:Period OR n:Source OR n:Claim
         DETACH DELETE n`,
      );
      console.log('Đã xoá đồ thị cũ (--reset)');
    }

    // Ràng buộc duy nhất kiêm chỉ mục — tra cứu theo id là truy vấn nóng nhất
    // của cả ba endpoint, không có chỉ mục thì Neo4j quét toàn bộ nhãn.
    for (const label of ['Entity', 'Period', 'Source', 'Claim']) {
      await session.run(
        `CREATE CONSTRAINT ${label.toLowerCase()}_id_unique IF NOT EXISTS
         FOR (n:${label}) REQUIRE n.id IS UNIQUE`,
      );
    }
    await session.run(
      `CREATE INDEX entity_search_name IF NOT EXISTS
       FOR (e:Entity) ON (e.searchName)`,
    );

    await session.run(
      `UNWIND $rows AS row
       MERGE (p:Period {id: row.id})
       SET p.name = row.name, p.start = row.start, p.end = row.end`,
      { rows: data.periods },
    );

    await session.run(
      `UNWIND $rows AS row
       MERGE (s:Source {id: row.id})
       SET s.title = row.title, s.note = row.note`,
      {
        rows: data.sources.map((s) => ({ ...s, note: s.note ?? null })),
      },
    );

    await session.run(
      `UNWIND $rows AS row
       MERGE (e:Entity {id: row.id})
       SET e.type = row.type, e.name = row.name,
           e.searchName = row.searchName,
           e.aliases = row.aliases, e.searchAliases = row.searchAliases,
           e.date = row.date,
           e.description = row.description, e.note = row.note`,
      {
        rows: data.entities.map((e) => {
          const aliases = (e.aliases ?? [])
            .map((alias) => alias.trim())
            .filter(Boolean);
          return {
            id: e.id,
            type: e.type,
            name: e.name,
            searchName: normalizeVietnamese(e.name),
            // Mảng rỗng chứ không null: bên đọc luôn nhận về một danh sách.
            aliases,
            searchAliases: aliases.map((alias) => normalizeVietnamese(alias)),
            date: e.date?.trim() || null,
            description: e.description ?? null,
            note: e.note ?? null,
          };
        }),
      },
    );

    const periodLinks = data.entities
      .filter((e) => e.period_id)
      .map((e) => ({ entityId: e.id, periodId: e.period_id }));
    await session.run(
      `UNWIND $rows AS row
       MATCH (e:Entity {id: row.entityId}), (p:Period {id: row.periodId})
       MERGE (e)-[:IN_PERIOD]->(p)`,
      { rows: periodLinks },
    );

    const sourceLinks = data.entities.flatMap((e) =>
      (e.source_ids ?? []).map((sid) => ({ entityId: e.id, sourceId: sid })),
    );
    await session.run(
      `UNWIND $rows AS row
       MATCH (e:Entity {id: row.entityId}), (s:Source {id: row.sourceId})
       MERGE (e)-[:CITED_BY]->(s)`,
      { rows: sourceLinks },
    );

    // Loại quan hệ nằm trong thuộc tính `type` chứ không thành nhiều loại cạnh
    // Cypher riêng: nhờ vậy truy vấn đa bước không phải liệt kê trước danh
    // sách loại quan hệ, thêm loại mới không cần sửa truy vấn. `type` phải nằm
    // trong mẫu MERGE, không chỉ SET sau — nếu không, hai quan hệ khác loại
    // giữa cùng cặp thực thể sẽ bị gộp thành một cạnh.
    await session.run(
      `UNWIND $rows AS row
       MATCH (h:Entity {id: row.head}), (t:Entity {id: row.tail})
       MERGE (h)-[r:RELATION {type: row.relation}]->(t)
       SET r.note = row.note, r.sourceIds = row.sourceIds`,
      {
        rows: data.relations.map((r) => ({
          head: r.head,
          tail: r.tail,
          relation: r.relation,
          note: r.note ?? null,
          sourceIds: r.source_ids ?? [],
        })),
      },
    );

    // Nhận định tranh cãi: một Claim nói VỀ một thực thể, mỗi nguồn giữ một
    // lập trường. Cạnh của claim được xoá rồi dựng lại mỗi lần chạy thay vì
    // MERGE: hai lập trường có thể cùng một nguồn, và một lập trường bị bỏ
    // khỏi tệp phải biến mất khỏi đồ thị — MERGE không làm được cả hai.
    // `order` giữ đúng thứ tự trong tệp để bên đọc liệt kê như người soạn.
    await session.run(
      `UNWIND $rows AS row
       MERGE (c:Claim {id: row.id})
       SET c.description = row.description
       WITH c
       OPTIONAL MATCH (c)-[old:ABOUT|POSITION]->()
       DELETE old`,
      {
        rows: claims.map((c) => ({ id: c.id, description: c.description })),
      },
    );
    await session.run(
      `UNWIND $rows AS row
       MATCH (c:Claim {id: row.claimId}), (e:Entity {id: row.entityId})
       MERGE (c)-[:ABOUT]->(e)`,
      {
        rows: claims.map((c) => ({
          claimId: c.id,
          entityId: c.topic_entity_id,
        })),
      },
    );
    await session.run(
      `UNWIND $rows AS row
       MATCH (c:Claim {id: row.claimId}), (s:Source {id: row.sourceId})
       CREATE (c)-[:POSITION {text: row.text, order: row.order}]->(s)`,
      {
        rows: claims.flatMap((c) =>
          (c.positions ?? []).map((position, order) => ({
            claimId: c.id,
            sourceId: position.source_id,
            text: position.claim,
            order,
          })),
        ),
      },
    );

    const counts = await session.run(
      `MATCH (e:Entity) WITH count(e) AS entities
       MATCH (p:Period) WITH entities, count(p) AS periods
       MATCH (s:Source) WITH entities, periods, count(s) AS sources
       MATCH ()-[r:RELATION]->() WITH entities, periods, sources, count(r) AS relations
       MATCH ()-[ip:IN_PERIOD]->() WITH entities, periods, sources, relations, count(ip) AS inPeriod
       MATCH ()-[c:CITED_BY]->()
       WITH entities, periods, sources, relations, inPeriod, count(c) AS citedBy
       OPTIONAL MATCH (cl:Claim)
       WITH entities, periods, sources, relations, inPeriod, citedBy,
            count(cl) AS claims
       OPTIONAL MATCH (:Claim)-[pos:POSITION]->(:Source)
       WITH entities, periods, sources, relations, inPeriod, citedBy, claims,
            count(pos) AS positions
       OPTIONAL MATCH (dated:Entity) WHERE dated.date IS NOT NULL
       WITH entities, periods, sources, relations, inPeriod, citedBy, claims,
            positions, count(dated) AS dated
       OPTIONAL MATCH (aliased:Entity) WHERE size(aliased.aliases) > 0
       RETURN entities, periods, sources, relations, inPeriod, citedBy, claims,
              positions, dated, count(aliased) AS aliased`,
    );
    const row = counts.records[0];
    console.log(
      'Đồ thị sau khi nạp: ' +
        `${row.get('entities')} thực thể, ` +
        `${row.get('periods')} thời kỳ, ` +
        `${row.get('sources')} nguồn, ` +
        `${row.get('relations')} quan hệ, ` +
        `${row.get('inPeriod')} liên kết thời kỳ, ` +
        `${row.get('citedBy')} liên kết nguồn, ` +
        `${row.get('claims')} nhận định (${row.get('positions')} lập trường), ` +
        `${row.get('dated')} thực thể có ngày, ` +
        `${row.get('aliased')} thực thể có bí danh`,
    );
  } finally {
    await session.close();
    await driver.close();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
