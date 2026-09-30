# HDDhistory — Học lịch sử Việt Nam bằng đồ thị tri thức

Đồ án tốt nghiệp — Học viện Công nghệ Bưu chính Viễn thông (PTIT).

Hệ thống học lịch sử Việt Nam dựa trên **đồ thị tri thức** (knowledge graph)
kết hợp **nhúng đồ thị** (KGE) để đo độ tương đồng giữa các thực thể và gợi ý
nội dung liên quan.

## Nội dung repo

| Thư mục | Nội dung |
|---|---|
| `knowledge-graph/` | Tầng tri thức: pipeline trích xuất từ Wikidata, huấn luyện KGE (TransE), đo độ tương đồng, và **bộ dữ liệu lịch sử Việt Nam tự soạn** |
| `web/` | Giao diện web (Next.js): tra cứu đồ thị, đọc nội dung khoá học |
| `bao-cao/` | Mã nguồn sinh quyển báo cáo (`.docx`) |

## Bộ dữ liệu

`knowledge-graph/data/vn_history/vn_history_seed.json` — soạn thủ công và đối
chiếu với Wikidata:

- **176 thực thể**: 76 nhân vật, 43 sự kiện, 31 triều đại/tổ chức, 10 địa danh
- **205 quan hệ** thuộc 35 loại (`led`, `founded`, `succeeded`, `child_of`…)
- **12 thời kỳ** lịch sử, **11 nguồn** sử liệu được trích dẫn

Phủ từ thời Hồng Bàng tới hiện đại.

## Tầng tri thức

Pipeline sáu bước trong `knowledge-graph/src/`, viết ở dạng jupytext (giải
thích bằng văn xuôi trước mỗi khối mã):

1. Trích xuất thực thể từ Wikidata qua SPARQL
2. Làm sạch và chuẩn hoá thành bộ ba `(head, relation, tail)`
3. Huấn luyện nhúng TransE bằng PyKEEN
4. Đo độ tương đồng bằng cosine trên không gian nhúng
5. Gợi ý thực thể liên quan
6. Sinh câu hỏi từ đồ thị

Kết quả đo và phân tích nằm trong `knowledge-graph/notebooks/`.

## Chạy thử

### Đồ thị tri thức (Neo4j)

```bash
docker run -d --name hddhistory-neo4j -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/<mật khẩu> neo4j:5-community
```

### Web

```bash
cd web
cp .env.example .env.local     # trỏ API_BASE_URL vào API
npm install
npm run dev                    # http://localhost:3000
```

### Báo cáo

```bash
cd bao-cao
npm install
node build.js                  # sinh bao-cao-do-an.docx
```

## Quan hệ với nền tảng Meup

Phần tích hợp vào ứng dụng di động và API của nền tảng Meup (thuộc EUP) **không
nằm trong repo này**. Repo này chỉ chứa phần do tác giả tự xây dựng: tầng tri
thức, bộ dữ liệu, giao diện web và quyển báo cáo.
