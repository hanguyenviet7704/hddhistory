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
 * Đọc NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD từ env/.env
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import neo4j, { Driver } from 'neo4j-driver';

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
interface SeedFile {
  periods: SeedPeriod[];
  sources: SeedSource[];
  entities: SeedEntity[];
  relations: SeedRelation[];
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

/**
 * Bỏ dấu tiếng Việt để tìm kiếm không dấu vẫn khớp. Giữ đồng bộ với
 * src/modules/knowledge-graph/util/normalize-vietnamese.util.ts — nếu sửa một
 * bên mà quên bên kia, dữ liệu nạp vào sẽ không khớp được với truy vấn.
 */
function normalizeVietnamese(input: string): string {
  return input
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

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
  console.log(
    `Nguồn: ${file}\n` +
      `  ${data.periods.length} thời kỳ, ${data.sources.length} nguồn, ` +
      `${data.entities.length} thực thể, ${data.relations.length} quan hệ`,
  );

  const driver: Driver = neo4j.driver(
    NEO4J_URI,
    neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD),
  );
  const session = driver.session();

  try {
    if (reset) {
      await session.run(
        'MATCH (n) WHERE n:Entity OR n:Period OR n:Source DETACH DELETE n',
      );
      console.log('Đã xoá đồ thị cũ (--reset)');
    }

    // Ràng buộc duy nhất kiêm chỉ mục — tra cứu theo id là truy vấn nóng nhất
    // của cả ba endpoint, không có chỉ mục thì Neo4j quét toàn bộ nhãn.
    for (const label of ['Entity', 'Period', 'Source']) {
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
           e.description = row.description, e.note = row.note`,
      {
        rows: data.entities.map((e) => ({
          id: e.id,
          type: e.type,
          name: e.name,
          searchName: normalizeVietnamese(e.name),
          description: e.description ?? null,
          note: e.note ?? null,
        })),
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
       SET r.note = row.note`,
      {
        rows: data.relations.map((r) => ({
          head: r.head,
          tail: r.tail,
          relation: r.relation,
          note: r.note ?? null,
        })),
      },
    );

    const counts = await session.run(
      `MATCH (e:Entity) WITH count(e) AS entities
       MATCH (p:Period) WITH entities, count(p) AS periods
       MATCH (s:Source) WITH entities, periods, count(s) AS sources
       MATCH ()-[r:RELATION]->() WITH entities, periods, sources, count(r) AS relations
       MATCH ()-[ip:IN_PERIOD]->() WITH entities, periods, sources, relations, count(ip) AS inPeriod
       MATCH ()-[c:CITED_BY]->()
       RETURN entities, periods, sources, relations, inPeriod, count(c) AS citedBy`,
    );
    const row = counts.records[0];
    console.log(
      'Đồ thị sau khi nạp: ' +
        `${row.get('entities')} thực thể, ` +
        `${row.get('periods')} thời kỳ, ` +
        `${row.get('sources')} nguồn, ` +
        `${row.get('relations')} quan hệ, ` +
        `${row.get('inPeriod')} liên kết thời kỳ, ` +
        `${row.get('citedBy')} liên kết nguồn`,
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
