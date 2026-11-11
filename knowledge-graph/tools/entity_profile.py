"""Hồ sơ thực thể dựng từ đồ thị tri thức: "nhân vật này là ai, đã làm gì".

Đọc `data/vn_history/vn_history_seed.json` và in ra một thẻ hồ sơ gồm: mô tả,
thời kỳ, các việc đã làm (quan hệ đi ra), những ai/việc nhắc tới thực thể này
(quan hệ đi vào), thực thể cùng thời kỳ, và nguồn. Phần này thuần tra cứu đồ
thị — chạy tức thì, không cần mạng, không cần Neo4j, không cần API key.

Tuỳ chọn `--kge` thêm mục "gần nhất theo KGE": top-k thực thể có cosine
similarity cao nhất trên không gian embedding TransE. Lần đầu phải huấn luyện
(~5-10 giây) rồi lưu cache vào `data/processed/entity_embeddings.npz`; các lần
sau đọc cache nên tức thì.

Cách dùng:
    python tools/entity_profile.py "Trần Hưng Đạo"
    python tools/entity_profile.py "Trần Hưng Đạo" --kge
    python tools/entity_profile.py --rebuild-embeddings   # huấn luyện lại cache

LƯU Ý VỀ CHẤT LƯỢNG KGE: embedding hiện huấn luyện trên một đồ thị nhỏ
(~186 thực thể / 381 triples, MRR≈0.07), nên mục "gần nhất theo KGE" mang tính
minh hoạ pipeline hơn là một gợi ý ngữ nghĩa đáng tin. Phần còn lại của hồ sơ
lấy trực tiếp từ dữ liệu đã rà soát nên không chịu hạn chế này.
"""
import argparse
import json
import sys
import unicodedata
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
DATASET_PATH = ROOT / "data" / "vn_history" / "vn_history_seed.json"
TRIPLES_PATH = ROOT / "data" / "vn_history" / "vn_history_triples.csv"
EMBEDDINGS_PATH = ROOT / "data" / "processed" / "entity_embeddings.npz"

TYPE_LABELS = {
    "figure": "nhân vật",
    "event": "sự kiện",
    "organization": "tổ chức / triều đại",
    "place": "địa danh",
}

# Nhãn quan hệ sang tiếng Việt cho dễ đọc. Quan hệ chưa có trong bảng này sẽ
# hiện nguyên tên gốc — thêm loại quan hệ mới không làm hỏng hồ sơ.
RELATION_LABELS = {
    "served": "phục vụ",
    "led": "lãnh đạo",
    "founded": "sáng lập",
    "opposed": "chống lại",
    "participated_in": "tham gia",
    "succeeded": "kế tục",
    "contemporary_with": "cùng thời với",
    "part_of": "thuộc về",
    "child_of": "là con của",
    "followed": "diễn ra sau",
    "resulted_in": "dẫn đến",
    "initiated": "khởi xướng",
    "preceded": "diễn ra trước",
    "considered_ancestor_of": "được coi là tổ tiên của",
    "built": "xây dựng",
    "occurred_at": "diễn ra tại",
    "border_at": "lấy ranh giới tại",
    "capital_at": "đóng đô tại",
    "ended": "chấm dứt",
    "married": "kết hôn với",
    "conquered": "thôn tính",
    "ruled_during": "trị vì trong",
    "enacted": "ban hành",
    "controlled": "nắm quyền chi phối",
    "defeated": "đánh bại",
    "authored": "soạn",
    "ruled": "cai trị",
    "moved_capital_to": "dời đô về",
    "led_to": "dẫn tới",
    "imposed_on": "áp đặt lên",
    "declared": "đặt quốc hiệu",
    "commissioned_by": "được biên soạn dưới thời",
    "developed": "phát triển",
    "allied_with": "liên minh với",
    "renamed_from": "đổi tên từ",
    "worships": "thờ",
    "native_of": "quê ở",
    "sibling_of": "là anh chị em với",
}


def _normalize(text: str) -> str:
    """Bỏ dấu, hạ chữ thường, gom khoảng trắng — để so khớp tên gõ không dấu."""
    text = text.replace("đ", "d").replace("Đ", "D")
    stripped = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    return " ".join(stripped.lower().split())


def load_dataset(path: Path = DATASET_PATH) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def find_entity(dataset: dict, query: str):
    """Tìm thực thể theo id, theo tên chính xác, hoặc theo tên không dấu.
    Trả về dict thực thể, hoặc None nếu không tìm thấy."""
    for entity in dataset["entities"]:
        if entity["id"] == query or entity["name"] == query:
            return entity
    target = _normalize(query)
    for entity in dataset["entities"]:
        if _normalize(entity["name"]) == target or _normalize(entity["id"].replace("_", " ")) == target:
            return entity
    # khớp theo phần trước dấu ngoặc, vd "Hoàng Hoa Thám (Đề Thám)"
    for entity in dataset["entities"]:
        if _normalize(entity["name"].split("(")[0]) == target:
            return entity
    return None


def build_profile(dataset: dict, entity_id: str) -> dict:
    """Gom mọi thứ đồ thị biết về một thực thể."""
    by_id = {e["id"]: e for e in dataset["entities"]}
    if entity_id not in by_id:
        raise KeyError(f"Không có thực thể id={entity_id!r} trong dataset")
    entity = by_id[entity_id]

    outgoing = [
        {"relation": r["relation"], "target": by_id[r["tail"]], "note": r.get("note")}
        for r in dataset["relations"] if r["head"] == entity_id
    ]
    incoming = [
        {"relation": r["relation"], "source": by_id[r["head"]], "note": r.get("note")}
        for r in dataset["relations"] if r["tail"] == entity_id
    ]
    same_period = [
        e for e in dataset["entities"]
        if e.get("period_id") == entity.get("period_id") and e["id"] != entity_id
    ]
    periods_by_id = {p["id"]: p for p in dataset["periods"]}
    sources_by_id = {s["id"]: s for s in dataset["sources"]}

    return {
        "entity": entity,
        "period": periods_by_id.get(entity.get("period_id")),
        "outgoing": outgoing,
        "incoming": incoming,
        "same_period": same_period,
        "sources": [sources_by_id[sid] for sid in entity.get("source_ids", []) if sid in sources_by_id],
    }


def format_profile(profile: dict, similar=None, same_period_limit: int = 8) -> str:
    """Dựng thẻ hồ sơ dạng text. `similar` = list (label, score) từ KGE, bỏ qua nếu None."""
    entity = profile["entity"]
    period = profile["period"]
    lines = []

    lines.append(entity["name"].upper())
    meta = TYPE_LABELS.get(entity["type"], entity["type"])
    if period:
        meta += f" · Thời kỳ: {period['name']} ({period['start']}–{period['end']})"
    lines.append(meta)
    lines.append("")

    lines.append(f"Là ai: {entity.get('description', '(chưa có mô tả)')}")
    if entity.get("note"):
        lines.append(f"Ghi chú: {entity['note']}")
    lines.append("")

    if profile["outgoing"]:
        lines.append("Đã làm gì (quan hệ đi ra):")
        for rel in profile["outgoing"]:
            label = RELATION_LABELS.get(rel["relation"], rel["relation"])
            line = f"  • {label} → {rel['target']['name']}"
            if rel.get("note"):
                line += f"  ({rel['note']})"
            lines.append(line)
        lines.append("")

    if profile["incoming"]:
        lines.append("Được nhắc tới bởi (quan hệ đi vào):")
        for rel in profile["incoming"]:
            label = RELATION_LABELS.get(rel["relation"], rel["relation"])
            lines.append(f"  • {rel['source']['name']} — {label} → (thực thể này)")
        lines.append("")

    if profile["same_period"]:
        names = [e["name"] for e in profile["same_period"]]
        shown = ", ".join(names[:same_period_limit])
        if len(names) > same_period_limit:
            shown += f", … (+{len(names) - same_period_limit} thực thể khác)"
        lines.append(f"Cùng thời kỳ: {shown}")
        lines.append("")

    if similar:
        lines.append("Gần nhất theo KGE (cosine similarity trên embedding):")
        for label, score in similar:
            lines.append(f"  • {label}  ({score:.2f})")
        lines.append("")

    if profile["sources"]:
        lines.append("Nguồn: " + "; ".join(s["title"] for s in profile["sources"]))

    return "\n".join(lines)


# --- Phần KGE: huấn luyện một lần, lưu cache, tra nhanh về sau -----------------

def build_embeddings_cache(triples_csv: Path = TRIPLES_PATH,
                           out_path: Path = EMBEDDINGS_PATH,
                           num_epochs: int = 100) -> dict:
    """Huấn luyện TransE trên triples CSV rồi lưu embedding ra .npz.
    Dùng lại nguyên hàm huấn luyện của Bước 3 để số liệu nhất quán với báo cáo."""
    sys.path.insert(0, str(ROOT))
    from src.step3_train_kge import triples_csv_to_factory, train_transe

    tf = triples_csv_to_factory(str(triples_csv))
    result = train_transe(tf, num_epochs=num_epochs)
    matrix = result.model.entity_representations[0](indices=None).detach().numpy()

    labels = list(tf.entity_to_id.keys())
    vectors = np.array([matrix[tf.entity_to_id[label]] for label in labels])

    out_path.parent.mkdir(parents=True, exist_ok=True)
    np.savez(out_path, labels=np.array(labels, dtype=object), vectors=vectors)
    return {"labels": labels, "vectors": vectors}


def load_embeddings(path: Path = EMBEDDINGS_PATH) -> dict:
    data = np.load(path, allow_pickle=True)
    return {"labels": list(data["labels"]), "vectors": data["vectors"]}


def most_similar(embeddings: dict, label: str, top_k: int = 5):
    """Top-k nhãn gần nhất theo cosine similarity. [] nếu label không có trong cache."""
    labels, vectors = embeddings["labels"], embeddings["vectors"]
    if label not in labels:
        return []
    target = vectors[labels.index(label)]
    norms = np.linalg.norm(vectors, axis=1) * np.linalg.norm(target)
    # numpy 2.0 + Accelerate BLAS (macOS) phát RuntimeWarning "divide by zero /
    # overflow / invalid encountered in matmul" ngay cả với dữ liệu float32
    # sạch hoàn toàn (đã kiểm chứng bằng ma trận random) — đây là dương tính
    # giả của BLAS, không phải lỗi dữ liệu. Tắt riêng cho phép nhân này; giá
    # trị không hữu hạn (nếu có thật) vẫn bị lọc ở dòng dưới.
    with np.errstate(divide="ignore", over="ignore", invalid="ignore"):
        scores = (vectors @ target) / np.where(norms == 0, 1, norms)
    order = np.argsort(-scores)
    out = [(labels[i], float(scores[i])) for i in order
           if labels[i] != label and np.isfinite(scores[i])]
    return out[:top_k]


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                      formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("name", nargs="?", help="Tên hoặc id thực thể (gõ có dấu hay không đều được)")
    parser.add_argument("--kge", action="store_true", help="Thêm mục gợi ý gần nhất theo embedding KGE")
    parser.add_argument("--top-k", type=int, default=5, help="Số gợi ý KGE (mặc định 5)")
    parser.add_argument("--rebuild-embeddings", action="store_true",
                         help="Huấn luyện lại và ghi đè cache embedding rồi thoát")
    args = parser.parse_args()

    if args.rebuild_embeddings:
        print("Đang huấn luyện TransE và lưu cache embedding...")
        cache = build_embeddings_cache()
        print(f"Đã lưu {len(cache['labels'])} embedding vào {EMBEDDINGS_PATH}")
        return

    if not args.name:
        parser.error("Cần tên thực thể (hoặc --rebuild-embeddings)")

    dataset = load_dataset()
    entity = find_entity(dataset, args.name)
    if entity is None:
        print(f"Không tìm thấy thực thể nào khớp {args.name!r} trong dataset.")
        sys.exit(1)

    profile = build_profile(dataset, entity["id"])

    similar = None
    if args.kge:
        if not EMBEDDINGS_PATH.exists():
            print("Chưa có cache embedding — đang huấn luyện lần đầu (một lần duy nhất)...")
            build_embeddings_cache()
        similar = most_similar(load_embeddings(), entity["name"], top_k=args.top_k)
        if not similar:
            print(f"(Lưu ý: {entity['name']!r} không có trong cache embedding — "
                  f"có thể dataset đã đổi, chạy --rebuild-embeddings để cập nhật.)\n")

    print(format_profile(profile, similar=similar))


if __name__ == "__main__":
    main()
