"""Tool GỢI Ý quan hệ còn thiếu giữa các thực thể ĐÃ CÓ trong
data/vn_history/vn_history_seed.json, dựa trên vợ/chồng (P26) và
cha/mẹ/con (P22/P25/P40) tra trên Wikidata. Thuần code, không dùng AI.

CHỈ IN GỢI Ý RA MÀN HÌNH, KHÔNG TỰ GHI FILE. Khác với
wikidata_entity_importer.py (tạo thực thể mới, tự tin ghi thẳng), việc suy ra
một QUAN HỆ giữa hai thực thể có sẵn rủi ro sai cao hơn nhiều: trùng tên
(nhiều nhân vật lịch sử Việt Nam cùng tên), hoặc thực thể trong bộ dữ liệu
của ta là một biến thể/giản lược khác với thực thể Wikidata tìm được. Vì vậy
mọi gợi ý đều cần người rà soát rồi mới thêm tay vào vn_history_seed.json —
không có cờ "--apply" tự động ghi.

Cách dùng:
    python tools/wikidata_relation_suggester.py --names "Nguyễn Huệ" "Lê Lợi"
    python tools/wikidata_relation_suggester.py --degree-at-most 1
        (quét mọi thực thể hiện có bậc <= 1 quan hệ trong dataset)
"""
import argparse
import json
import time
import urllib.parse
from collections import Counter
from pathlib import Path

from wikidata_entity_importer import (
    DATASET_PATH,
    USER_AGENT,
    WIKIDATA_SPARQL_ENDPOINT,
    _http_get_json,
    load_dataset,
    search_qid_by_name,
    slugify_vi,
)

# P22 cha, P25 mẹ, P40 con -> quan hệ nội bộ (head, relation, tail_là_gì)
# "reverse" nghĩa là thực thể tìm được (X) đứng ở vị trí head, thực thể gốc
# đứng ở vị trí tail của quan hệ đó.
FAMILY_PROPERTIES = {
    "P22": ("child_of", False),   # X là cha -> (gốc, child_of, X)
    "P25": ("child_of", False),   # X là mẹ -> (gốc, child_of, X)
    "P40": ("child_of", True),    # X là con -> (X, child_of, gốc)
}
SPOUSE_PROPERTY = "P26"


def fetch_family_and_spouse(qid: str) -> dict:
    """Trả về {"spouse": [(qid,label)...], "father": [...], "mother": [...],
    "child": [...]}."""
    query = f"""
    SELECT ?spouse ?spouseLabel ?father ?fatherLabel ?mother ?motherLabel
           ?child ?childLabel WHERE {{
      OPTIONAL {{ wd:{qid} wdt:P26 ?spouse }}
      OPTIONAL {{ wd:{qid} wdt:P22 ?father }}
      OPTIONAL {{ wd:{qid} wdt:P25 ?mother }}
      OPTIONAL {{ wd:{qid} wdt:P40 ?child }}
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "vi,en". }}
    }}
    """
    url = f"{WIKIDATA_SPARQL_ENDPOINT}?{urllib.parse.urlencode({'query': query, 'format': 'json'})}"
    data = _http_get_json(url)
    bindings = data["results"]["bindings"]

    result = {"spouse": set(), "father": set(), "mother": set(), "child": set()}
    for b in bindings:
        for field, key in [("spouse", "spouse"), ("father", "father"),
                            ("mother", "mother"), ("child", "child")]:
            if field in b:
                qid_v = b[field]["value"].rsplit("/", 1)[-1]
                label_v = b.get(f"{field}Label", {}).get("value", qid_v)
                result[key].add((qid_v, label_v))
    return result


def build_local_lookup(entities: list) -> dict:
    """slug(name) -> entity id, để khớp tên Wikidata với thực thể đã có."""
    lookup = {}
    for e in entities:
        lookup[slugify_vi(e["name"])] = e["id"]
        # cũng khớp theo phần trước dấu ngoặc, vd "Hoàng Hoa Thám (Đề Thám)" -> "hoang_hoa_tham"
        base_name = e["name"].split("(")[0].strip()
        lookup.setdefault(slugify_vi(base_name), e["id"])
    return lookup


def existing_relation_exists(relations: list, head: str, tail: str) -> bool:
    return any((r["head"] == head and r["tail"] == tail) or
               (r["head"] == tail and r["tail"] == head) for r in relations)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--names", nargs="+", default=[], help="Tên thực thể ĐÃ CÓ trong dataset cần dò thêm quan hệ")
    parser.add_argument("--degree-at-most", type=int, default=None,
                         help="Quét mọi thực thể hiện có bậc <= N quan hệ (bỏ qua --names)")
    args = parser.parse_args()

    dataset = load_dataset(DATASET_PATH)
    entities = dataset["entities"]
    relations = dataset["relations"]
    lookup = build_local_lookup(entities)
    by_id = {e["id"]: e for e in entities}

    if args.degree_at_most is not None:
        deg = Counter()
        for r in relations:
            deg[r["head"]] += 1
            deg[r["tail"]] += 1
        targets = [e["name"] for e in entities if deg.get(e["id"], 0) <= args.degree_at_most
                   and e["type"] == "figure"]
        print(f"Quét {len(targets)} thực thể loại 'figure' có bậc <= {args.degree_at_most}...")
    else:
        targets = args.names

    if not targets:
        parser.error("Cần --names hoặc --degree-at-most")

    suggestions = []
    for i, name in enumerate(targets):
        if i > 0:
            time.sleep(2.5)
        head_id = lookup.get(slugify_vi(name))
        if head_id is None:
            print(f"[{name}] không khớp thực thể nào trong dataset theo tên, bỏ qua.")
            continue

        candidates = search_qid_by_name(name)
        if not candidates:
            print(f"[{name}] không tìm thấy trên Wikidata.")
            continue
        qid = candidates[0]["qid"]

        time.sleep(1)
        fam = fetch_family_and_spouse(qid)

        found_any = False
        for spouse_qid, spouse_label in fam["spouse"]:
            tail_id = lookup.get(slugify_vi(spouse_label))
            if tail_id and tail_id != head_id and not existing_relation_exists(relations, head_id, tail_id):
                suggestions.append({"head": head_id, "relation": "married", "tail": tail_id,
                                     "evidence": f"{name} <-> {spouse_label} (Wikidata P26, {qid}<->{spouse_qid})"})
                found_any = True
        for father_qid, father_label in fam["father"]:
            tail_id = lookup.get(slugify_vi(father_label))
            if tail_id and tail_id != head_id and not existing_relation_exists(relations, head_id, tail_id):
                suggestions.append({"head": head_id, "relation": "child_of", "tail": tail_id,
                                     "evidence": f"{name} là con của {father_label} (Wikidata P22, {qid})"})
                found_any = True
        for mother_qid, mother_label in fam["mother"]:
            tail_id = lookup.get(slugify_vi(mother_label))
            if tail_id and tail_id != head_id and not existing_relation_exists(relations, head_id, tail_id):
                suggestions.append({"head": head_id, "relation": "child_of", "tail": tail_id,
                                     "evidence": f"{name} là con của {mother_label} (Wikidata P25, {qid})"})
                found_any = True
        for child_qid, child_label in fam["child"]:
            tail_id = lookup.get(slugify_vi(child_label))
            if tail_id and tail_id != head_id and not existing_relation_exists(relations, tail_id, head_id):
                suggestions.append({"head": tail_id, "relation": "child_of", "tail": head_id,
                                     "evidence": f"{child_label} là con của {name} (Wikidata P40, {qid})"})
                found_any = True

        status = "có gợi ý" if found_any else "không có quan hệ mới khớp dataset"
        print(f"[{name}] ({qid}) -> {status}")

    print(f"\n=== {len(suggestions)} gợi ý quan hệ (CẦN NGƯỜI RÀ SOÁT TRƯỚC KHI THÊM) ===")
    for s in suggestions:
        print(f'  {{"head": "{s["head"]}", "relation": "{s["relation"]}", "tail": "{s["tail"]}"}}  '
              f'<- {s["evidence"]}')

    if suggestions:
        out_path = Path(__file__).resolve().parent.parent / "data" / "vn_history" / "_relation_suggestions.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(suggestions, f, ensure_ascii=False, indent=2)
        print(f"\nĐã lưu gợi ý (kèm bằng chứng) vào {out_path} để tiện rà soát.")
        print("File này KHÔNG được dùng trực tiếp bởi pipeline nào — chỉ là nháp để xem lại rồi tự tay chép")
        print("các quan hệ đúng vào vn_history_seed.json.")


if __name__ == "__main__":
    main()
