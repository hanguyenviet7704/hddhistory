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
# Truy vấn với limit=1000 lấy được **1000 triples**. Kết quả đạt đủ 1000 triples
# (chính xác là limit đã đặt), điều này cho thấy còn dữ liệu ngoài giới hạn trong
# Wikidata. Phạm vi hiện tại (7 loại quan hệ + điều kiện quốc gia Việt Nam) đã
# đủ cho Task 1, và dữ liệu được lưu vào `data/raw/triples.csv`.

# %%
if __name__ == "__main__":
    import os
    query = build_sparql_query(limit=1000)
    bindings = run_query(query)
    triples = bindings_to_triples(bindings)
    print(f"Số triples lấy được: {len(triples)}")
    os.makedirs("data/raw", exist_ok=True)
    save_triples_csv(triples, "data/raw/triples.csv")
