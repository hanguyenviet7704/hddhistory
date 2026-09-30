# Tầng tri thức & tầng sinh nội dung — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng pipeline 6 bước (Wikidata → Neo4j → KGE → similarity → relation
chain → sinh câu hỏi có kiểm soát) trên dữ liệu công khai, và từ đó tạo ra một
**báo cáo** (notebook) giải thích công thức + ví dụ thật cho từng bước — đây
mới là sản phẩm nộp, code chỉ là công cụ tạo ra số liệu/ví dụ thật cho báo cáo.

**Architecture:** Mỗi bước là một file Python định dạng jupytext "percent"
(`# %% [markdown]` xen với `# %%` code) trong `src/` — vừa là module Python
import/test được bằng pytest, vừa là nguồn cho notebook cuối cùng (Task 7 ghép
6 file lại và convert bằng `jupytext --to notebook`). Neo4j chạy qua Docker
Compose; PyKEEN huấn luyện KGE trực tiếp từ CSV triples (không cần Neo4j cho
bước huấn luyện — Neo4j chỉ dùng để lưu và truy vấn multi-hop ở Bước 2 và 5).

**Tech Stack:** Python 3.9 (venv), SPARQLWrapper, neo4j (driver Python),
pykeen + torch, pandas, numpy, scikit-learn, matplotlib, anthropic (SDK Claude
cho bước sinh câu hỏi), jupytext, pytest. Neo4j 5 Community qua Docker Compose.

**Spec:** `/Users/nguyenvietha/Source/HDDhistory/knowledge-graph/docs/superpowers/specs/2026-09-21-knowledge-content-layer-design.md`

## Global Constraints

- Mỗi file `src/stepN_*.py` PHẢI có markdown cell giải thích (công thức + ý
  nghĩa) TRƯỚC đoạn code liên quan — báo cáo là sản phẩm chính, không phải phụ.
- Sau khi một bước chạy thật lần đầu, PHẢI cập nhật markdown cell "Ví dụ minh
  hoạ" bằng số liệu/kết quả THẬT quan sát được — không bịa số, không để trống.
- Máy hiện tại: Python 3.9.6, không có Homebrew, Docker đã cài nhưng daemon
  chưa chạy (`open -a Docker` rồi đợi trước khi dùng `docker compose`), 16GB RAM.
- Neo4j chạy qua Docker Compose, tài khoản cố định `neo4j`/`kg-research-pw`.
- Wikidata: quốc gia Việt Nam = `Q881`, endpoint `https://query.wikidata.org/sparql`.
- Sinh câu hỏi dùng Claude API (`anthropic` SDK, model `claude-sonnet-5`) —
  cần biến môi trường `ANTHROPIC_API_KEY` khi chạy thật; test không gọi mạng
  (dùng fake client).
- Toàn bộ nằm trong `knowledge-graph/` (repo Git riêng đã tạo, đã có
  `docs/superpowers/specs/2026-09-21-knowledge-content-layer-design.md`).

---

## Task 1: Môi trường + Bước 1 — Trích subgraph Wikidata

**Files:**
- Create: `knowledge-graph/requirements.txt`
- Create: `knowledge-graph/.gitignore`
- Create: `knowledge-graph/docker-compose.yml`
- Create: `knowledge-graph/conftest.py`
- Create: `knowledge-graph/src/step1_extract_wikidata.py`
- Test: `knowledge-graph/tests/test_step1_extract_wikidata.py`

**Interfaces:**
- Produces: `build_sparql_query(country_qid: str = "Q881", limit: int = 1000) -> str`,
  `run_query(query: str, endpoint: str = WIKIDATA_ENDPOINT) -> list[dict]`,
  `bindings_to_triples(bindings: list[dict]) -> list[dict]` (mỗi dict có
  `head_qid, head_label, relation_pid, relation_label, tail_qid, tail_label`),
  `save_triples_csv(triples: list[dict], path: str) -> None`.
  Task 2/3/5/6 đều đọc `data/raw/triples.csv` với đúng 6 cột trên.

- [ ] **Step 1: Tạo venv và cài thư viện**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/knowledge-graph
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install SPARQLWrapper pandas numpy neo4j scikit-learn matplotlib \
            anthropic jupytext pytest
pip install pykeen
```

Nếu `pip install pykeen` báo lỗi không tương thích với Python 3.9.6 (torch
hoặc pykeen yêu cầu Python mới hơn), thử cài torch CPU trước rồi pykeen:

```bash
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install pykeen
```

Ghi lại phiên bản thực sự cài được:

```bash
pip freeze > requirements.txt
```

- [ ] **Step 2: Tạo `.gitignore`**

```
.venv/
__pycache__/
*.pyc
.pytest_cache/
notebooks/_combined_report.py
```

- [ ] **Step 3: Tạo `docker-compose.yml`**

```yaml
services:
  neo4j:
    image: neo4j:5-community
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      - NEO4J_AUTH=neo4j/kg-research-pw
    volumes:
      - neo4j_data:/data

volumes:
  neo4j_data:
```

- [ ] **Step 4: Tạo `conftest.py` ở root để pytest import được `src`**

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
```

- [ ] **Step 5: Viết `src/step1_extract_wikidata.py`**

```python
# %% [markdown]
# ## Bước 1 — Trích subgraph lịch sử Việt Nam từ Wikidata
#
# Wikidata là một cơ sở tri thức mở: mỗi thực thể có một mã định danh (QID,
# ví dụ Hồ Chí Minh là `Q10520`), mỗi loại quan hệ có một mã thuộc tính (PID,
# ví dụ "quốc gia" là `P17`). Bước này dùng SPARQL — ngôn ngữ truy vấn chuẩn
# cho dữ liệu RDF/triple — để lấy về các thực thể liên quan lịch sử Việt Nam
# cùng quan hệ giữa chúng, dưới dạng triples `(head, relation, tail)`.
#
# Truy vấn lấy mọi thực thể có `wdt:P17` (quốc gia) là Việt Nam (`wd:Q881`),
# cùng các quan hệ: người tham gia (`P710`), thời điểm (`P585`), thời điểm bắt
# đầu/kết thúc (`P580`/`P582`), địa điểm (`P276`), nguyên nhân (`P828`), vị trí
# /chức vụ (`P39`). Độ phủ thật của Wikidata cho từng quan hệ chưa biết trước
# — số liệu thật được ghi lại ở phần "Chạy thật" dưới đây, quyết định có cần
# mở rộng phạm vi lọc hay không dựa trên số liệu đó, không đoán trước.

# %%
from SPARQLWrapper import SPARQLWrapper, JSON
import csv

WIKIDATA_ENDPOINT = "https://query.wikidata.org/sparql"
VIETNAM_QID = "Q881"


def build_sparql_query(country_qid: str = VIETNAM_QID, limit: int = 1000) -> str:
    """Trả về câu SPARQL lấy thực thể liên quan lịch sử Việt Nam kèm quan hệ."""
    return f"""
    SELECT ?head ?headLabel ?relation ?relationLabel ?tail ?tailLabel WHERE {{
      ?head wdt:P17 wd:{country_qid} .
      {{ ?head wdt:P710 ?tail . BIND(wd:P710 AS ?relation) }}
      UNION {{ ?head wdt:P585 ?tail . BIND(wd:P585 AS ?relation) }}
      UNION {{ ?head wdt:P580 ?tail . BIND(wd:P580 AS ?relation) }}
      UNION {{ ?head wdt:P582 ?tail . BIND(wd:P582 AS ?relation) }}
      UNION {{ ?head wdt:P276 ?tail . BIND(wd:P276 AS ?relation) }}
      UNION {{ ?head wdt:P828 ?tail . BIND(wd:P828 AS ?relation) }}
      UNION {{ ?head wdt:P39 ?tail . BIND(wd:P39 AS ?relation) }}
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "vi,en". }}
    }}
    LIMIT {limit}
    """


def run_query(query: str, endpoint: str = WIKIDATA_ENDPOINT) -> list:
    """Gọi SPARQL endpoint, trả về list các dict bindings thô."""
    sparql = SPARQLWrapper(endpoint, agent="hddhistory-kg-research/0.1")
    sparql.setQuery(query)
    sparql.setReturnFormat(JSON)
    results = sparql.query().convert()
    return results["results"]["bindings"]


def _qid_from_uri(uri: str) -> str:
    """Lấy QID/PID từ URI Wikidata, ví dụ '.../entity/Q881' -> 'Q881'."""
    return uri.rsplit("/", 1)[-1]


def _tail_value(binding_tail: dict) -> str:
    """Nếu tail là một thực thể (URI) thì lấy QID, nếu là literal (ví dụ ngày
    tháng) thì giữ nguyên giá trị."""
    if binding_tail.get("type") == "uri":
        return _qid_from_uri(binding_tail["value"])
    return binding_tail["value"]


def bindings_to_triples(bindings: list) -> list:
    """Chuyển kết quả SPARQL thô thành list triples có cấu trúc."""
    triples = []
    for b in bindings:
        triples.append({
            "head_qid": _qid_from_uri(b["head"]["value"]),
            "head_label": b.get("headLabel", {}).get("value", ""),
            "relation_pid": _qid_from_uri(b["relation"]["value"]),
            "relation_label": b.get("relationLabel", {}).get("value", ""),
            "tail_qid": _tail_value(b["tail"]),
            "tail_label": b.get("tailLabel", {}).get("value", ""),
        })
    return triples


def save_triples_csv(triples: list, path: str) -> None:
    """Lưu triples ra CSV."""
    fieldnames = ["head_qid", "head_label", "relation_pid", "relation_label",
                  "tail_qid", "tail_label"]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(triples)


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Điền số liệu thật sau khi chạy — xem Step 8 của Task 1 trong plan.)_

# %%
if __name__ == "__main__":
    import os
    query = build_sparql_query(limit=1000)
    bindings = run_query(query)
    triples = bindings_to_triples(bindings)
    print(f"Số triples lấy được: {len(triples)}")
    os.makedirs("data/raw", exist_ok=True)
    save_triples_csv(triples, "data/raw/triples.csv")
```

- [ ] **Step 6: Viết test `tests/test_step1_extract_wikidata.py`**

```python
from src.step1_extract_wikidata import bindings_to_triples, save_triples_csv


def test_bindings_to_triples_handles_uri_and_literal_tail():
    bindings = [
        {
            "head": {"type": "uri", "value": "http://www.wikidata.org/entity/Q10520"},
            "headLabel": {"value": "Hồ Chí Minh"},
            "relation": {"type": "uri", "value": "http://www.wikidata.org/entity/P39"},
            "relationLabel": {"value": "chức vụ"},
            "tail": {"type": "uri", "value": "http://www.wikidata.org/entity/Q1234"},
            "tailLabel": {"value": "Chủ tịch nước"},
        },
        {
            "head": {"type": "uri", "value": "http://www.wikidata.org/entity/Q10520"},
            "headLabel": {"value": "Hồ Chí Minh"},
            "relation": {"type": "uri", "value": "http://www.wikidata.org/entity/P569"},
            "relationLabel": {"value": "ngày sinh"},
            "tail": {"type": "literal", "value": "1890-05-19T00:00:00Z"},
            "tailLabel": {"value": "1890-05-19T00:00:00Z"},
        },
    ]
    triples = bindings_to_triples(bindings)
    assert triples[0]["head_qid"] == "Q10520"
    assert triples[0]["tail_qid"] == "Q1234"
    assert triples[1]["tail_qid"] == "1890-05-19T00:00:00Z"


def test_save_triples_csv_writes_header_and_rows(tmp_path):
    triples = [{
        "head_qid": "Q1", "head_label": "A", "relation_pid": "P1",
        "relation_label": "rel", "tail_qid": "Q2", "tail_label": "B",
    }]
    out = tmp_path / "triples.csv"
    save_triples_csv(triples, str(out))
    content = out.read_text(encoding="utf-8")
    assert "head_qid,head_label,relation_pid,relation_label,tail_qid,tail_label" in content
    assert "Q1,A,P1,rel,Q2,B" in content
```

- [ ] **Step 7: Chạy test, xác nhận PASS**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/knowledge-graph
source .venv/bin/activate
pytest tests/test_step1_extract_wikidata.py -v
```
Expected: cả 2 test PASS, không gọi mạng.

- [ ] **Step 8: Chạy thật với Wikidata, ghi số liệu thật vào markdown**

```bash
python -m src.step1_extract_wikidata
```

Đọc số triples in ra. Mở lại `src/step1_extract_wikidata.py`, sửa đoạn
`### Ví dụ minh hoạ (chạy thật)` — thay dòng "_(Điền số liệu thật...)_" bằng
số triples thật, và nếu số quá nhỏ (< 100), ghi rõ quyết định tiếp theo (mở
rộng `limit`, hoặc bỏ bớt điều kiện lọc quốc gia) kèm lý do — đây chính là nội
dung sẽ vào báo cáo.

- [ ] **Step 9: Commit**

```bash
git add requirements.txt .gitignore docker-compose.yml conftest.py \
        src/step1_extract_wikidata.py tests/test_step1_extract_wikidata.py \
        data/raw/triples.csv
git commit -m "feat: bước 1 - trích subgraph Wikidata lịch sử Việt Nam"
```

---

## Task 2: Bước 2 — Nạp subgraph vào Neo4j

**Files:**
- Create: `knowledge-graph/src/step2_load_neo4j.py`
- Test: `knowledge-graph/tests/test_step2_load_neo4j.py`

**Interfaces:**
- Consumes: `data/raw/triples.csv` (từ Task 1, cột `head_qid, head_label,
  relation_pid, relation_label, tail_qid, tail_label`).
- Produces: `get_driver(uri, user, password)`, `load_triples(driver,
  triples: list[dict]) -> dict` (trả `{"triples_loaded": int}`),
  `load_triples_from_csv(driver, csv_path: str) -> dict`,
  `count_nodes_and_relationships(driver) -> dict` (trả `{"node_count": int,
  "relationship_count": int}`). Task 5 dùng cùng Neo4j (label `Entity`,
  quan hệ `RELATION` với thuộc tính `pid`/`label`) để truy vấn multi-hop.

- [ ] **Step 1: Khởi động Docker và Neo4j**

```bash
open -a Docker
```

Đợi Docker Desktop khởi động xong (icon hết animation), rồi:

```bash
cd /Users/nguyenvietha/Source/HDDhistory/knowledge-graph
docker compose up -d
docker compose ps
```
Expected: container `neo4j` ở trạng thái `running`, healthy sau ~30s.

- [ ] **Step 2: Viết `src/step2_load_neo4j.py`**

```python
# %% [markdown]
# ## Bước 2 — Nạp subgraph vào Neo4j
#
# Neo4j là một cơ sở dữ liệu đồ thị: dữ liệu được lưu trực tiếp dưới dạng nút
# (node) và cạnh (relationship) có thuộc tính, khác với việc mô phỏng đồ thị
# bằng bảng quan hệ. Bước này đọc file triples từ Bước 1 và nạp vào Neo4j
# bằng lệnh Cypher `MERGE` — `MERGE` chỉ tạo mới nếu nút/cạnh chưa tồn tại,
# nên chạy lại script nhiều lần không tạo dữ liệu trùng.
#
# Mỗi thực thể trở thành một nút nhãn `Entity` với thuộc tính `qid` và
# `label`. Mọi quan hệ dùng chung một loại cạnh Cypher `RELATION`, mang thuộc
# tính `pid` và `label` riêng — thay vì tạo một loại cạnh khác nhau cho mỗi
# quan hệ — để Bước 5 (truy vấn multi-hop) không phải liệt kê trước tên loại
# quan hệ cụ thể.

# %%
import csv
from neo4j import GraphDatabase


def get_driver(uri: str, user: str, password: str):
    """Tạo Neo4j driver."""
    return GraphDatabase.driver(uri, auth=(user, password))


def _load_one_triple(tx, triple: dict) -> None:
    tx.run(
        """
        MERGE (h:Entity {qid: $head_qid})
        SET h.label = $head_label
        MERGE (t:Entity {qid: $tail_qid})
        SET t.label = $tail_label
        MERGE (h)-[r:RELATION {pid: $relation_pid}]->(t)
        SET r.label = $relation_label
        """,
        head_qid=triple["head_qid"],
        head_label=triple["head_label"],
        tail_qid=triple["tail_qid"],
        tail_label=triple["tail_label"],
        relation_pid=triple["relation_pid"],
        relation_label=triple["relation_label"],
    )


def load_triples(driver, triples: list) -> dict:
    """Nạp triples vào Neo4j, trả về {"triples_loaded": int}."""
    with driver.session() as session:
        for triple in triples:
            session.execute_write(_load_one_triple, triple)
    return {"triples_loaded": len(triples)}


def load_triples_from_csv(driver, csv_path: str) -> dict:
    """Đọc CSV rồi gọi load_triples."""
    with open(csv_path, encoding="utf-8") as f:
        triples = list(csv.DictReader(f))
    return load_triples(driver, triples)


def count_nodes_and_relationships(driver) -> dict:
    """Đếm số nút/cạnh thật đang có trong Neo4j — đối chiếu với báo cáo."""
    with driver.session() as session:
        node_count = session.run("MATCH (n:Entity) RETURN count(n) AS c").single()["c"]
        rel_count = session.run("MATCH ()-[r:RELATION]->() RETURN count(r) AS c").single()["c"]
    return {"node_count": node_count, "relationship_count": rel_count}


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Điền số liệu thật sau khi chạy: số triples nạp, số nút, số cạnh — số nút
# thường nhỏ hơn số triples vì nhiều triples chia sẻ cùng thực thể.)_

# %%
if __name__ == "__main__":
    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    result = load_triples_from_csv(driver, "data/raw/triples.csv")
    counts = count_nodes_and_relationships(driver)
    print(f"Đã nạp {result['triples_loaded']} triples")
    print(f"Neo4j hiện có {counts['node_count']} nút, {counts['relationship_count']} cạnh")
    driver.close()
```

- [ ] **Step 3: Viết test `tests/test_step2_load_neo4j.py`**

```python
import pytest
from src.step2_load_neo4j import get_driver, load_triples, count_nodes_and_relationships


@pytest.fixture()
def driver():
    d = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    yield d
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    d.close()


def test_load_triples_creates_expected_nodes_and_relationships(driver):
    triples = [
        {"head_qid": "Q1", "head_label": "A", "tail_qid": "Q2", "tail_label": "B",
         "relation_pid": "P1", "relation_label": "rel"},
    ]
    result = load_triples(driver, triples)
    assert result["triples_loaded"] == 1
    counts = count_nodes_and_relationships(driver)
    assert counts["node_count"] == 2
    assert counts["relationship_count"] == 1
```

- [ ] **Step 4: Chạy test (cần Neo4j đang chạy từ Step 1), xác nhận PASS**

```bash
pytest tests/test_step2_load_neo4j.py -v
```
Expected: PASS. Nếu lỗi kết nối `ServiceUnavailable`, kiểm tra lại
`docker compose ps` — container phải ở trạng thái running.

- [ ] **Step 5: Chạy thật, nạp toàn bộ triples.csv, ghi số liệu vào markdown**

```bash
python -m src.step2_load_neo4j
```

Cập nhật đoạn "Ví dụ minh hoạ" trong `step2_load_neo4j.py` với số liệu thật in
ra (số triples nạp, số nút, số cạnh).

- [ ] **Step 6: Commit**

```bash
git add src/step2_load_neo4j.py tests/test_step2_load_neo4j.py
git commit -m "feat: bước 2 - nạp subgraph vào Neo4j"
```

---

## Task 3: Bước 3 — Huấn luyện KGE bằng PyKEEN

**Files:**
- Create: `knowledge-graph/src/step3_train_kge.py`
- Test: `knowledge-graph/tests/test_step3_train_kge.py`

**Interfaces:**
- Consumes: `data/raw/triples.csv` (trực tiếp, không qua Neo4j).
- Produces: `triples_csv_to_factory(csv_path: str) -> TriplesFactory`,
  `train_transe(tf, train_ratio=0.8, num_epochs=100, random_seed=42) ->
  PipelineResult`, `extract_eval_metrics(result) -> dict` (trả `{"mrr":
  float, "hits_at_1": float, "hits_at_3": float, "hits_at_10": float}`),
  `save_eval_json(metrics: dict, path: str) -> None`. Task 4 dùng
  `PipelineResult` (biến `result`) trả về từ `train_transe` để lấy embedding.

- [ ] **Step 1: Viết `src/step3_train_kge.py`**

```python
# %% [markdown]
# ## Bước 3 — Huấn luyện Knowledge Graph Embeddings (KGE)
#
# KGE học một vector số (embedding) cho mỗi thực thể và mỗi loại quan hệ, sao
# cho cấu trúc đồ thị được giữ lại trong không gian vector. Bước này dùng
# **TransE** — mô hình KGE cổ điển, dễ diễn giải nhất — làm baseline.
#
# **Công thức điểm số TransE:** với một triple `(h, r, t)`, TransE giả định
# `h + r ≈ t` nếu triple đúng, và định nghĩa hàm điểm số
#
# `score(h, r, t) = -‖ h + r - t ‖`
#
# (dùng khoảng cách L1 hoặc L2; lấy dấu âm để điểm số cao hơn nghĩa là đúng
# hơn). Mô hình huấn luyện bằng **margin ranking loss**: với mỗi triple đúng
# `(h, r, t)`, sinh một triple sai bằng cách thay `h` hoặc `t` bằng một thực
# thể ngẫu nhiên khác (negative sampling), rồi tối ưu để
# `score(h, r, t) > score(h', r, t') + margin`.
#
# **Đánh giá:** với mỗi triple trong tập test, mô hình xếp hạng mọi thực thể
# có thể là `t` theo điểm số, rồi xem thực thể đúng đứng hạng thứ mấy.
# - `MRR` (Mean Reciprocal Rank) = trung bình của `1/hạng` trên toàn tập test.
# - `Hits@k` = tỉ lệ các triple mà thực thể đúng nằm trong top-k.

# %%
from pykeen.triples import TriplesFactory
from pykeen.pipeline import pipeline as pykeen_pipeline
import pandas as pd
import json


def triples_csv_to_factory(csv_path: str) -> TriplesFactory:
    """Đọc triples CSV, trả về TriplesFactory dùng label làm định danh."""
    df = pd.read_csv(csv_path)
    triples_array = df[["head_label", "relation_label", "tail_label"]].to_numpy()
    return TriplesFactory.from_labeled_triples(triples_array)


def train_transe(tf: TriplesFactory, train_ratio: float = 0.8,
                  num_epochs: int = 100, random_seed: int = 42):
    """Chia train/test, huấn luyện TransE, trả về PipelineResult."""
    training, testing = tf.split([train_ratio, 1 - train_ratio],
                                  random_state=random_seed)
    result = pykeen_pipeline(
        training=training,
        testing=testing,
        model="TransE",
        random_seed=random_seed,
        training_kwargs=dict(num_epochs=num_epochs),
    )
    return result


def extract_eval_metrics(result) -> dict:
    """Trích MRR/Hits@k bằng API get_metric (ổn định qua các bản PyKEEN)."""
    mr = result.metric_results
    return {
        "mrr": mr.get_metric("mrr"),
        "hits_at_1": mr.get_metric("hits_at_1"),
        "hits_at_3": mr.get_metric("hits_at_3"),
        "hits_at_10": mr.get_metric("hits_at_10"),
    }


def save_eval_json(metrics: dict, path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Điền MRR/Hits@1/3/10 thật sau khi chạy. Nếu `get_metric` báo lỗi tên
# metric không tồn tại, in `result.metric_results.to_dict()` ra để xem đúng
# tên khoá, rồi sửa lại `extract_eval_metrics` cho khớp.)_

# %%
if __name__ == "__main__":
    import os
    tf = triples_csv_to_factory("data/raw/triples.csv")
    result = train_transe(tf, num_epochs=100)
    metrics = extract_eval_metrics(result)
    print(json.dumps(metrics, ensure_ascii=False, indent=2))
    os.makedirs("reports", exist_ok=True)
    save_eval_json(metrics, "reports/kge_eval.json")
```

- [ ] **Step 2: Viết test `tests/test_step3_train_kge.py`**

```python
import numpy as np
from pykeen.triples import TriplesFactory
from src.step3_train_kge import train_transe, extract_eval_metrics


def test_train_transe_returns_valid_metrics():
    rng = np.random.default_rng(0)
    entities = [f"e{i}" for i in range(12)]
    relations = ["r0", "r1", "r2"]
    triples = np.array([
        [rng.choice(entities), rng.choice(relations), rng.choice(entities)]
        for _ in range(60)
    ])
    tf = TriplesFactory.from_labeled_triples(triples)
    result = train_transe(tf, train_ratio=0.8, num_epochs=5, random_seed=0)
    metrics = extract_eval_metrics(result)
    for key in ["mrr", "hits_at_1", "hits_at_3", "hits_at_10"]:
        assert 0.0 <= metrics[key] <= 1.0
```

- [ ] **Step 3: Chạy test, xác nhận PASS**

```bash
pytest tests/test_step3_train_kge.py -v
```
Expected: PASS (có thể chạy vài chục giây do PyTorch khởi tạo). Nếu
`get_metric` ném lỗi tên không hợp lệ, sửa theo hướng dẫn trong comment ở
Step 1, chạy lại test tới khi PASS.

- [ ] **Step 4: Chạy thật trên `data/raw/triples.csv`, ghi số liệu vào markdown**

```bash
python -m src.step3_train_kge
```

Điền MRR/Hits@1/3/10 thật vào đoạn "Ví dụ minh hoạ". Nếu số triples ở Task 1
quá ít khiến train/test split gần như trống, quay lại Task 1 Step 8 mở rộng
`limit`/điều kiện lọc trước khi tiếp tục.

- [ ] **Step 5: Commit**

```bash
git add src/step3_train_kge.py tests/test_step3_train_kge.py reports/kge_eval.json
git commit -m "feat: bước 3 - huấn luyện KGE bằng PyKEEN"
```

---

## Task 4: Bước 4 — Độ tương đồng giữa thực thể + trực quan hoá

**Files:**
- Create: `knowledge-graph/src/step4_similarity.py`
- Test: `knowledge-graph/tests/test_step4_similarity.py`

**Interfaces:**
- Consumes: `PipelineResult` từ `train_transe` (Task 3).
- Produces: `get_entity_embedding(result, entity_label: str) -> np.ndarray`,
  `cosine_similarity(u, v) -> float`, `most_similar(result, entity_label,
  candidate_labels, top_k=5) -> list[tuple[str, float]]`,
  `plot_embeddings_2d(result, labels, out_path) -> None`.

- [ ] **Step 1: Viết `src/step4_similarity.py`**

```python
# %% [markdown]
# ## Bước 4 — Tính độ tương đồng giữa các thực thể
#
# Mỗi thực thể sau khi huấn luyện có một vector embedding. Độ tương đồng
# cosine giữa hai vector u, v:
#
# `sim(u, v) = (u · v) / (‖u‖ ‖v‖)`
#
# Giá trị nằm trong [-1, 1]; gần 1 nghĩa là hai thực thể "gần nhau" trong
# không gian embedding — với KGE, điều này thường tương ứng với việc hai thực
# thể xuất hiện trong ngữ cảnh quan hệ tương tự nhau trên đồ thị (ví dụ hai
# nhân vật cùng tham gia một tổ chức, hoặc hai sự kiện cùng một địa điểm).

# %%
import numpy as np
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt


def get_entity_embedding(result, entity_label: str) -> np.ndarray:
    """Lấy vector embedding của 1 thực thể theo label."""
    entity_id = result.training.entities_to_ids([entity_label])[0]
    embedding_tensor = result.model.entity_representations[0](indices=None)
    return embedding_tensor[entity_id].detach().numpy()


def cosine_similarity(u: np.ndarray, v: np.ndarray) -> float:
    """sim(u, v) = (u·v) / (‖u‖‖v‖)."""
    return float(np.dot(u, v) / (np.linalg.norm(u) * np.linalg.norm(v)))


def most_similar(result, entity_label: str, candidate_labels: list, top_k: int = 5):
    """Top_k thực thể (trong candidate_labels) có similarity cao nhất với entity_label."""
    target = get_entity_embedding(result, entity_label)
    scored = []
    for label in candidate_labels:
        if label == entity_label:
            continue
        vec = get_entity_embedding(result, label)
        scored.append((label, cosine_similarity(target, vec)))
    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[:top_k]


def plot_embeddings_2d(result, labels: list, out_path: str = "reports/embedding_plot.png") -> None:
    """Giảm chiều bằng PCA và vẽ scatter các thực thể trong labels."""
    vectors = np.array([get_entity_embedding(result, label) for label in labels])
    coords = PCA(n_components=2, random_state=0).fit_transform(vectors)
    plt.figure(figsize=(8, 6))
    plt.scatter(coords[:, 0], coords[:, 1])
    for (x, y), label in zip(coords, labels):
        plt.annotate(label, (x, y))
    plt.title("Thực thể trong không gian embedding (PCA 2D)")
    plt.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close()


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Chọn 2 thực thể có liên hệ rõ trong subgraph thật — ví dụ hai nhân vật
# cùng một tổ chức/sự kiện — và 2 thực thể không liên quan. Điền similarity
# thật của từng cặp vào đây, kèm nhận xét embedding có phản ánh đúng cấu trúc
# đồ thị hay không. Đính kèm `reports/embedding_plot.png` vào báo cáo.)_

# %%
if __name__ == "__main__":
    from src.step3_train_kge import triples_csv_to_factory, train_transe

    tf = triples_csv_to_factory("data/raw/triples.csv")
    result = train_transe(tf, num_epochs=100)
    all_labels = list(tf.entity_to_id.keys())
    sample_labels = all_labels[:20]
    plot_embeddings_2d(result, sample_labels)
    if len(all_labels) >= 2:
        print(most_similar(result, all_labels[0], all_labels, top_k=5))
```

- [ ] **Step 2: Viết test `tests/test_step4_similarity.py`**

```python
import numpy as np
from src.step4_similarity import cosine_similarity


def test_cosine_similarity_identical_vectors_is_one():
    v = np.array([1.0, 2.0, 3.0])
    assert abs(cosine_similarity(v, v) - 1.0) < 1e-9


def test_cosine_similarity_orthogonal_vectors_is_zero():
    u = np.array([1.0, 0.0])
    v = np.array([0.0, 1.0])
    assert abs(cosine_similarity(u, v)) < 1e-9


def test_cosine_similarity_opposite_vectors_is_negative_one():
    u = np.array([1.0, 0.0])
    v = np.array([-1.0, 0.0])
    assert abs(cosine_similarity(u, v) + 1.0) < 1e-9
```

- [ ] **Step 3: Chạy test, xác nhận PASS**

```bash
pytest tests/test_step4_similarity.py -v
```
Expected: PASS, không cần model đã huấn luyện (test chỉ kiểm công thức toán).

- [ ] **Step 4: Chạy thật, chọn ví dụ minh hoạ, ghi vào markdown**

```bash
python -m src.step4_similarity
```

Từ danh sách similarity in ra, chọn một cặp thực thể liên quan (similarity
cao) và một cặp không liên quan (similarity thấp hơn) để đối chiếu trong báo
cáo. Điền số liệu thật + nhận xét vào đoạn "Ví dụ minh hoạ".

- [ ] **Step 5: Commit**

```bash
git add src/step4_similarity.py tests/test_step4_similarity.py reports/embedding_plot.png
git commit -m "feat: bước 4 - độ tương đồng thực thể và trực quan hoá embedding"
```

---

## Task 5: Bước 5 — Trích chuỗi quan hệ làm ngữ cảnh

**Files:**
- Create: `knowledge-graph/src/step5_relation_chain.py`
- Test: `knowledge-graph/tests/test_step5_relation_chain.py`

**Interfaces:**
- Consumes: Neo4j đã nạp dữ liệu (Task 2), driver từ
  `step2_load_neo4j.get_driver`.
- Produces: `get_relation_chain(driver, qid: str, max_hops: int = 2, limit:
  int = 20) -> list[dict]` (mỗi dict có `subject, relation, object,
  source_pid`), `format_context(facts: list[dict]) -> str`. Task 6 dùng
  đúng shape `{"subject", "relation", "object", "source_pid"}` này làm `facts`.

- [ ] **Step 1: Viết `src/step5_relation_chain.py`**

```python
# %% [markdown]
# ## Bước 5 — Trích chuỗi quan hệ làm ngữ cảnh
#
# Để sinh câu hỏi có kiểm soát ở Bước 6, mô hình ngôn ngữ không được "tự nhớ"
# kiến thức lịch sử — mọi dữ kiện trong câu hỏi phải xuất phát từ một tập fact
# cụ thể, kiểm chứng lại được. Bước này lấy tập fact đó bằng cách truy vấn
# Cypher multi-hop quanh một thực thể mục tiêu trong Neo4j: đi tối đa
# `max_hops` cạnh từ thực thể đó, lấy mọi quan hệ gặp trên đường đi.

# %%
def get_relation_chain(driver, qid: str, max_hops: int = 2, limit: int = 20) -> list:
    """Lấy các quan hệ trong bán kính max_hops quanh thực thể qid."""
    query = f"""
    MATCH path = (e:Entity {{qid: $qid}})-[:RELATION*1..{max_hops}]-(other)
    UNWIND relationships(path) AS rel
    WITH DISTINCT startNode(rel) AS s, rel, endNode(rel) AS o
    RETURN s.label AS subject, rel.label AS relation, o.label AS object,
           rel.pid AS source_pid
    LIMIT $limit
    """
    with driver.session() as session:
        records = session.run(query, qid=qid, limit=limit)
        return [dict(r) for r in records]


def format_context(facts: list) -> str:
    """Chuyển list fact thành đoạn ngữ cảnh có cấu trúc, đánh số."""
    lines = []
    for i, fact in enumerate(facts, start=1):
        lines.append(
            f"{i}. {fact['subject']} --{fact['relation']}--> {fact['object']} "
            f"(nguồn: {fact['source_pid']})"
        )
    return "\n".join(lines)


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Chọn 1 thực thể quan trọng trong subgraph, in ra chuỗi quan hệ thật quanh
# nó, dán nguyên văn `format_context(...)` vào đây làm ví dụ cho báo cáo.)_

# %%
if __name__ == "__main__":
    from src.step2_load_neo4j import get_driver

    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    # Thay QID dưới đây bằng một QID thật có trong data/raw/triples.csv
    example_qid = "Q10520"
    facts = get_relation_chain(driver, example_qid, max_hops=2, limit=20)
    print(format_context(facts))
    driver.close()
```

- [ ] **Step 2: Viết test `tests/test_step5_relation_chain.py`**

```python
import pytest
from src.step2_load_neo4j import get_driver, load_triples
from src.step5_relation_chain import get_relation_chain, format_context


def test_format_context_numbers_each_fact():
    facts = [
        {"subject": "Hồ Chí Minh", "relation": "tham gia",
         "object": "Đảng Cộng sản Việt Nam", "source_pid": "P710"},
        {"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
         "object": "1930", "source_pid": "P585"},
    ]
    context = format_context(facts)
    assert "1. Hồ Chí Minh --tham gia--> Đảng Cộng sản Việt Nam (nguồn: P710)" in context
    assert "2. Đảng Cộng sản Việt Nam --thời điểm--> 1930 (nguồn: P585)" in context


@pytest.fixture()
def driver_with_seed_graph():
    d = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    load_triples(d, [
        {"head_qid": "Q1", "head_label": "A", "tail_qid": "Q2", "tail_label": "B",
         "relation_pid": "P1", "relation_label": "quan hệ 1"},
        {"head_qid": "Q2", "head_label": "B", "tail_qid": "Q3", "tail_label": "C",
         "relation_pid": "P2", "relation_label": "quan hệ 2"},
    ])
    yield d
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    d.close()


def test_get_relation_chain_returns_multi_hop_facts(driver_with_seed_graph):
    facts = get_relation_chain(driver_with_seed_graph, "Q1", max_hops=2, limit=20)
    subjects_objects = {(f["subject"], f["object"]) for f in facts}
    assert ("A", "B") in subjects_objects
    assert ("B", "C") in subjects_objects
```

- [ ] **Step 3: Chạy test (Neo4j phải đang chạy), xác nhận PASS**

```bash
pytest tests/test_step5_relation_chain.py -v
```
Expected: PASS.

- [ ] **Step 4: Chạy thật với 1 thực thể thật trong subgraph, ghi vào markdown**

Sửa `example_qid` trong `src/step5_relation_chain.py` thành một QID thật có
trong `data/raw/triples.csv` (mở file CSV, chọn 1 thực thể có nhiều quan hệ),
chạy:

```bash
python -m src.step5_relation_chain
```

Dán nguyên văn output vào đoạn "Ví dụ minh hoạ" trong file.

- [ ] **Step 5: Commit**

```bash
git add src/step5_relation_chain.py tests/test_step5_relation_chain.py
git commit -m "feat: bước 5 - trích chuỗi quan hệ multi-hop làm ngữ cảnh"
```

---

## Task 6: Bước 6 — Sinh câu hỏi có kiểm soát

**Files:**
- Create: `knowledge-graph/src/step6_generate_question.py`
- Test: `knowledge-graph/tests/test_step6_generate_question.py`

**Interfaces:**
- Consumes: `facts: list[dict]` shape từ Task 5
  (`{"subject", "relation", "object", "source_pid"}`), `format_context`
  từ Task 5.
- Produces: `build_prompt(context: str) -> str`, `call_llm(prompt: str,
  client=None) -> str`, `extract_years(text: str) -> set`,
  `extract_allowed_years(facts) -> set`, `extract_allowed_names(facts) ->
  set`, `validate_question(question_json: dict, facts: list[dict]) -> dict`
  (trả `{"accepted": bool, "reason": str | None}`).

- [ ] **Step 1: Viết `src/step6_generate_question.py`**

```python
# %% [markdown]
# ## Bước 6 — Sinh câu hỏi có kiểm soát
#
# Prompt chỉ chứa các fact đã trích ở Bước 5 — mô hình không được dùng kiến
# thức nền riêng của nó. Sau khi mô hình trả lời, một bước kiểm tra tự động
# đối chiếu lại với chính các fact đầu vào theo 2 tiêu chí:
#
# 1. **Năm**: mọi số 4 chữ số xuất hiện trong câu hỏi/đáp án/giải thích phải
#    có mặt trong các fact đầu vào (trích bằng regex `\b\d{4}\b`, đối chiếu
#    tập hợp).
# 2. **Anchor**: mô hình phải tự khai những thực thể nó dùng (`anchors`), và
#    mọi anchor đó phải là một `subject`/`object` có thật trong fact đầu vào.
#
# Lý do dùng "anchor" thay vì cố dò tên riêng bằng regex trên toàn câu: tiếng
# Việt không viết hoa tên riêng theo quy tắc chặt như tiếng Anh, dò bằng regex
# dễ sai (bỏ sót hoặc bắt nhầm từ thường). Bắt mô hình khai báo anchor rồi đối
# chiếu tập hợp là một kiểm tra đáng tin cậy hơn nhiều.

# %%
import re
import json


def build_prompt(context: str) -> str:
    return (
        "Dưới đây là các dữ kiện lịch sử đã được xác minh:\n\n"
        f"{context}\n\n"
        "Hãy soạn một câu hỏi kiểm tra kiến thức dựa CHỈ trên các dữ kiện trên. "
        "Không dùng bất kỳ tên riêng hay năm nào không xuất hiện trong dữ kiện. "
        "Trả về đúng định dạng JSON, không thêm chữ nào khác:\n"
        '{"question": "...", "answer": "...", "explanation": "...", '
        '"anchors": ["..."]}'
    )


def call_llm(prompt: str, client=None) -> str:
    """Gọi Claude API, trả về text thô của phản hồi.
    `client` truyền vào để test bằng fake client, không gọi mạng thật."""
    if client is None:
        import anthropic
        client = anthropic.Anthropic()
    message = client.messages.create(
        model="claude-sonnet-5",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    return message.content[0].text


def extract_years(text: str) -> set:
    """Trích mọi số 4 chữ số trong text."""
    return set(re.findall(r"\b\d{4}\b", text))


def extract_allowed_years(facts: list) -> set:
    """Trích mọi năm 4 chữ số xuất hiện trong facts đầu vào."""
    allowed = set()
    for fact in facts:
        allowed |= extract_years(fact["subject"]) | extract_years(fact["object"])
    return allowed


def extract_allowed_names(facts: list) -> set:
    """Trích mọi subject/object xuất hiện trong facts đầu vào."""
    names = set()
    for fact in facts:
        names.add(fact["subject"])
        names.add(fact["object"])
    return names


def validate_question(question_json: dict, facts: list) -> dict:
    """Kiểm tra câu hỏi: (1) mọi năm phải có trong ngữ cảnh, (2) mọi anchor
    mô hình khai phải là một thực thể có thật trong facts đầu vào."""
    full_text = " ".join([
        question_json.get("question", ""),
        question_json.get("answer", ""),
        question_json.get("explanation", ""),
    ])
    used_years = extract_years(full_text)
    allowed_years = extract_allowed_years(facts)
    unmatched_years = used_years - allowed_years
    if unmatched_years:
        return {"accepted": False,
                "reason": f"Năm không có trong ngữ cảnh: {unmatched_years}"}

    allowed_names = extract_allowed_names(facts)
    anchors = set(question_json.get("anchors", []))
    if not anchors:
        return {"accepted": False, "reason": "Không có anchor nào được khai báo"}
    unmatched_anchors = anchors - allowed_names
    if unmatched_anchors:
        return {"accepted": False,
                "reason": f"Anchor không có trong ngữ cảnh: {unmatched_anchors}"}

    return {"accepted": True, "reason": None}


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Chạy với ngữ cảnh đầy đủ → dán câu hỏi được "accepted". Sau đó cố tình bỏ
# bớt 1 fact khỏi ngữ cảnh (ví dụ bỏ fact chứa năm) rồi chạy lại → dán câu hỏi
# bị "rejected" kèm lý do. Hai ví dụ này chứng minh cơ chế kiểm soát có tác
# dụng thật, không chỉ mô tả trên giấy.)_

# %%
if __name__ == "__main__":
    from src.step2_load_neo4j import get_driver
    from src.step5_relation_chain import get_relation_chain, format_context

    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    example_qid = "Q10520"  # thay bằng QID thật
    facts = get_relation_chain(driver, example_qid, max_hops=2, limit=20)
    driver.close()

    context = format_context(facts)
    prompt = build_prompt(context)
    raw_response = call_llm(prompt)
    question_json = json.loads(raw_response)
    result = validate_question(question_json, facts)
    print(json.dumps(question_json, ensure_ascii=False, indent=2))
    print(result)
```

- [ ] **Step 2: Viết test `tests/test_step6_generate_question.py`**

```python
from src.step6_generate_question import (
    call_llm, validate_question,
)


class _FakeContent:
    def __init__(self, text):
        self.text = text


class _FakeMessage:
    def __init__(self, text):
        self.content = [_FakeContent(text)]


class _FakeMessages:
    def __init__(self, text):
        self._text = text

    def create(self, **kwargs):
        return _FakeMessage(self._text)


class _FakeClient:
    def __init__(self, text):
        self.messages = _FakeMessages(text)


def test_call_llm_returns_text_from_client():
    client = _FakeClient('{"question": "test?"}')
    result = call_llm("prompt bất kỳ", client=client)
    assert "question" in result


def test_validate_question_accepts_when_years_and_anchors_match():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Đảng Cộng sản Việt Nam được thành lập năm nào?",
        "answer": "1930",
        "explanation": "Theo dữ kiện, Đảng Cộng sản Việt Nam có thời điểm là 1930.",
        "anchors": ["Đảng Cộng sản Việt Nam"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is True


def test_validate_question_rejects_year_outside_context():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Sự kiện này có liên quan gì đến năm 1945?",
        "answer": "Có",
        "explanation": "Năm 1945 là một mốc quan trọng khác.",
        "anchors": ["Đảng Cộng sản Việt Nam"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is False
    assert "1945" in result["reason"]


def test_validate_question_rejects_anchor_outside_context():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Ai thành lập tổ chức này?",
        "answer": "Hồ Chí Minh",
        "explanation": "Không có trong dữ kiện.",
        "anchors": ["Hồ Chí Minh"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is False


def test_validate_question_rejects_when_no_anchor_declared():
    facts = [{"subject": "A", "relation": "r", "object": "B", "source_pid": "P1"}]
    question = {"question": "?", "answer": "B", "explanation": "vì A r B", "anchors": []}
    result = validate_question(question, facts)
    assert result["accepted"] is False
```

- [ ] **Step 3: Chạy test, xác nhận PASS (không cần API key thật)**

```bash
pytest tests/test_step6_generate_question.py -v
```
Expected: tất cả PASS.

- [ ] **Step 4: Chạy thật 2 lần (đủ ngữ cảnh / thiếu ngữ cảnh), ghi vào markdown**

```bash
export ANTHROPIC_API_KEY=sk-...   # key thật của bạn
python -m src.step6_generate_question
```

Ghi lại output "accepted" thật. Sau đó sửa tạm script (xoá 1 fact khỏi
`facts` trước khi gọi `format_context`) để tạo ngữ cảnh thiếu, chạy lại, ghi
lại output "rejected" thật kèm lý do. Dán cả 2 ví dụ vào đoạn "Ví dụ minh
hoạ" trong file, rồi bỏ đoạn sửa tạm.

- [ ] **Step 5: Commit**

```bash
git add src/step6_generate_question.py tests/test_step6_generate_question.py
git commit -m "feat: bước 6 - sinh câu hỏi có kiểm soát và validate tự động"
```

---

## Task 7: Ghép notebook báo cáo hoàn chỉnh

**Files:**
- Create: `knowledge-graph/notebooks/build_report.py`
- Modify: (không sửa các file `src/step*.py`, chỉ đọc)

**Interfaces:**
- Consumes: 6 file `src/step1_extract_wikidata.py` … `src/step6_generate_question.py`
  (đã có markdown thật ở các Task trước, không phải bản còn "_(Điền số liệu...)_"`).
- Produces: `notebooks/01_pipeline_report.ipynb` — notebook báo cáo cuối cùng.

- [ ] **Step 1: Xác nhận không còn placeholder chưa điền**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/knowledge-graph
grep -rn "Điền số liệu\|Điền MRR\|Điền\b" src/
```
Expected: không có kết quả nào (mọi placeholder "Điền..." đã được thay bằng
số liệu thật ở các Task 1–6). Nếu còn, dừng lại và điền trước khi tiếp tục.

- [ ] **Step 2: Viết `notebooks/build_report.py`**

```python
"""Ghép 6 file src/stepN_*.py thành một notebook báo cáo duy nhất."""
from pathlib import Path

STEP_FILES = [
    "src/step1_extract_wikidata.py",
    "src/step2_load_neo4j.py",
    "src/step3_train_kge.py",
    "src/step4_similarity.py",
    "src/step5_relation_chain.py",
    "src/step6_generate_question.py",
]

HEADER = '''# %% [markdown]
# # Pipeline tầng tri thức và tầng sinh nội dung — Báo cáo
#
# Demo trên dữ liệu công khai Wikidata (lịch sử Việt Nam), theo yêu cầu của
# giáo viên hướng dẫn: chứng minh pipeline chạy được và hiểu rõ từng bước,
# trước khi áp dụng lên dữ liệu lịch sử Việt Nam tự soạn (giai đoạn 1858–1945)
# ở giai đoạn sau.
'''

FOOTER = '''# %% [markdown]
# ## Kết luận và hướng tiếp theo
#
# Pipeline đã chứng minh được trên dữ liệu Wikidata công khai: trích subgraph
# → lưu Neo4j → huấn luyện KGE → tính độ tương đồng → trích chuỗi quan hệ →
# sinh câu hỏi có kiểm soát với validate tự động chặn được nội dung sai lệch.
#
# Bước tiếp theo (ngoài phạm vi báo cáo này): áp dụng đúng pipeline này lên dữ
# liệu lịch sử Việt Nam tự soạn giai đoạn 1858–1945, rồi triển khai tầng lập
# lịch (Adaptive Microlearning Scheduling), tầng tương tác và tầng cập nhật
# đánh giá (Relational Diffusion) theo 5 tầng giáo viên đã giao.
'''


def build_combined(root: Path) -> str:
    parts = [HEADER]
    for rel_path in STEP_FILES:
        parts.append((root / rel_path).read_text(encoding="utf-8"))
    parts.append(FOOTER)
    return "\n\n".join(parts)


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    combined = build_combined(root)
    out_path = root / "notebooks" / "_combined_report.py"
    out_path.write_text(combined, encoding="utf-8")
    print(f"Đã ghép vào {out_path}")
    print("Chạy tiếp: jupytext --to notebook notebooks/_combined_report.py "
          "--output notebooks/01_pipeline_report.ipynb")
```

- [ ] **Step 3: Chạy script ghép và convert bằng jupytext**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/knowledge-graph
python notebooks/build_report.py
jupytext --to notebook notebooks/_combined_report.py \
  --output notebooks/01_pipeline_report.ipynb
```
Expected: file `notebooks/01_pipeline_report.ipynb` được tạo, không lỗi.

- [ ] **Step 4: Chạy toàn bộ notebook từ đầu đến cuối để xác nhận không lỗi**

Đảm bảo Docker/Neo4j đang chạy và `ANTHROPIC_API_KEY` đã export, rồi:

```bash
jupyter nbconvert --to notebook --execute \
  notebooks/01_pipeline_report.ipynb \
  --output 01_pipeline_report.ipynb
```
Expected: chạy xong không có cell lỗi. Nếu một cell lỗi do thứ tự phụ thuộc
(ví dụ Bước 4 cần `result` từ Bước 3 nhưng mỗi file `__main__` tự train lại
model riêng), đó là chấp nhận được — mỗi bước độc lập tái tạo dữ liệu nó cần,
không phụ thuộc biến toàn cục giữa các bước.

- [ ] **Step 5: Commit**

```bash
git add notebooks/build_report.py notebooks/01_pipeline_report.ipynb
git commit -m "docs: ghép notebook báo cáo hoàn chỉnh 6 bước"
```
