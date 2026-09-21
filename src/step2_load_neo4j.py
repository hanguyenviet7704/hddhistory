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
# Chạy `python -m src.step2_load_neo4j` để nạp toàn bộ `data/raw/triples.csv`
# (1000 dòng, sinh ra ở Bước 1) vào container Neo4j khởi động bằng
# `docker compose up -d`. Kết quả in ra từ lần chạy thật trên máy này:
#
# ```
# Đã nạp 1000 triples
# Neo4j hiện có 1017 nút, 1000 cạnh
# ```
#
# - Số triples nạp: **1000**
# - Số nút (`Entity`) sau khi nạp: **1017**
# - Số cạnh (`RELATION`) sau khi nạp: **1000**
#
# Số nút (1017) nhỏ hơn nhiều so với 2 × số triples (2000) vì phần lớn thực
# thể (ví dụ các nhân vật, địa danh, sự kiện lịch sử Việt Nam xuất hiện lặp
# lại) là head hoặc tail của nhiều triples khác nhau — `MERGE (h:Entity
# {qid: ...})` chỉ tạo nút mới lần đầu gặp một `qid`, các lần sau chỉ cập
# nhật thuộc tính `label` trên nút đã có. Đã kiểm chứng tính idempotent của
# `MERGE`: chạy lại `python -m src.step2_load_neo4j` lần hai cho đúng số liệu
# trên (1017 nút, 1000 cạnh) — không tạo dữ liệu trùng.

# %%
if __name__ == "__main__":
    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    result = load_triples_from_csv(driver, "data/raw/triples.csv")
    counts = count_nodes_and_relationships(driver)
    print(f"Đã nạp {result['triples_loaded']} triples")
    print(f"Neo4j hiện có {counts['node_count']} nút, {counts['relationship_count']} cạnh")
    driver.close()
