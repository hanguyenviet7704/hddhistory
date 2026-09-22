"""Chuyển data/vn_history/vn_history_seed.json (thực thể/quan hệ tự soạn)
sang triples CSV cùng định dạng data/raw/triples.csv, để dùng lại được
nguyên vẹn với src/step3_train_kge.py (không cần sửa code huấn luyện).

Tự thêm quan hệ "thuoc_thoi_ky" (thuộc thời kỳ) cho MỌI thực thể -> thời kỳ
của nó. Quan hệ này vốn đã có sẵn trong trường `period_id` của mỗi thực thể —
script chỉ hiện thực hoá nó thành một cạnh đồ thị thật, KHÔNG bịa thêm sự
kiện/quan hệ nào mới. Lý do cần làm việc này: kiểm tra thực tế cho thấy
45,6% thực thể trong bộ dữ liệu (73/160) chỉ có đúng 1 quan hệ (degree=1),
rất bất lợi cho việc huấn luyện KGE (một thực thể chỉ bị ràng buộc bởi 1
triple thì vị trí embedding gần như không xác định). Nối mọi thực thể vào
node thời kỳ của nó là cách tăng mật độ đồ thị rẻ nhất mà không thêm sai
lệch dữ liệu.

Cách dùng:
    python tools/vn_history_to_triples.py

Sau đó dùng lại các hàm có sẵn để huấn luyện KGE trên file CSV này, ví dụ:
    from src.step3_train_kge import triples_csv_to_factory, train_transe, extract_eval_metrics
    tf = triples_csv_to_factory("data/vn_history/vn_history_triples.csv")
    result = train_transe(tf, num_epochs=100)
    print(extract_eval_metrics(result))
"""
import csv
import json
from pathlib import Path

SEED_PATH = Path(__file__).resolve().parent.parent / "data" / "vn_history" / "vn_history_seed.json"
OUT_PATH = Path(__file__).resolve().parent.parent / "data" / "vn_history" / "vn_history_triples.csv"

FIELDNAMES = ["head_qid", "head_label", "relation_pid", "relation_label", "tail_qid", "tail_label"]


def build_rows(data: dict) -> list:
    entities_by_id = {e["id"]: e for e in data["entities"]}
    periods_by_id = {p["id"]: p for p in data["periods"]}

    rows = []
    for r in data["relations"]:
        head = entities_by_id[r["head"]]
        tail = entities_by_id[r["tail"]]
        rows.append({
            "head_qid": head["id"], "head_label": head["name"],
            "relation_pid": r["relation"], "relation_label": r["relation"],
            "tail_qid": tail["id"], "tail_label": tail["name"],
        })

    period_rows = []
    skipped_no_period = []
    for e in data["entities"]:
        period = periods_by_id.get(e.get("period_id"))
        if period is None:
            skipped_no_period.append(e["id"])
            continue
        period_rows.append({
            "head_qid": e["id"], "head_label": e["name"],
            "relation_pid": "thuoc_thoi_ky", "relation_label": "thuộc thời kỳ",
            "tail_qid": period["id"], "tail_label": period["name"],
        })

    return rows, period_rows, skipped_no_period


def main():
    with open(SEED_PATH, encoding="utf-8") as f:
        data = json.load(f)

    relation_rows, period_rows, skipped = build_rows(data)
    all_rows = relation_rows + period_rows

    with open(OUT_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(all_rows)

    print(f"Đã ghi {len(all_rows)} triples vào {OUT_PATH}:")
    print(f"  - {len(relation_rows)} quan hệ gốc từ vn_history_seed.json")
    print(f"  - {len(period_rows)} quan hệ 'thuộc thời kỳ' tự thêm")
    if skipped:
        print(f"  - {len(skipped)} thực thể KHÔNG có period_id hợp lệ, bỏ qua quan hệ thời kỳ: {skipped}")


if __name__ == "__main__":
    main()
