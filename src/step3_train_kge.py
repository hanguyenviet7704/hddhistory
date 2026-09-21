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
# Chạy `python -m src.step3_train_kge` để huấn luyện TransE thật trên toàn bộ
# `data/raw/triples.csv` (1000 dòng từ Bước 1; `TriplesFactory` gộp các triple
# trùng lặp còn lại **997 triple duy nhất**, trên **1009 thực thể** và **6**
# loại quan hệ), 100 epoch, `train_ratio` mặc định 0.8 (~797 triple train /
# ~200 triple test), `random_seed=42`. Kết quả đánh giá thật trên tập test, in
# ra từ lần chạy này trên máy này (đã lưu vào `reports/kge_eval.json`):
#
# ```json
# {
#   "mrr": 0.021817443892359734,
#   "hits_at_1": 0.0,
#   "hits_at_3": 0.0175,
#   "hits_at_10": 0.0475
# }
# ```
#
# - `MRR`: **0.0218** — nghịch đảo của nó (1/MRR ≈ 45.8) cho một ước lượng
#   thô về độ lớn thứ hạng trung bình của thực thể đúng, trên tổng số 1009
#   thực thể của đồ thị.
# - `Hits@1`: **0%**, `Hits@3`: **1.75%**, `Hits@10`: **4.75%**.
#
# Các số liệu này thấp — điều này hợp lý, không phải lỗi: 1000 triple được
# trích ra từ Wikidata theo 7 loại quan hệ cố định (Bước 1) tạo thành một đồ
# thị **rất thưa** (997 triple/1009 thực thể — trung bình mỗi thực thể chỉ
# xuất hiện trong ~2 triple), lại chia 80/20 nên tập test chỉ có ~200 triple
# để đánh giá trên toàn bộ không gian 1009 thực thể ứng viên. Với đồ thị thưa
# và ít epoch (100) như vậy, TransE khó học được biểu diễn tổng quát hoá tốt —
# baseline này dùng để minh hoạ đúng pipeline huấn luyện + đánh giá KGE, không
# nhằm đạt SOTA. `PipelineResult` (biến `result`) được Bước 4 dùng lại để
# trích embedding.

# %%
if __name__ == "__main__":
    import os
    tf = triples_csv_to_factory("data/raw/triples.csv")
    result = train_transe(tf, num_epochs=100)
    metrics = extract_eval_metrics(result)
    print(json.dumps(metrics, ensure_ascii=False, indent=2))
    os.makedirs("reports", exist_ok=True)
    save_eval_json(metrics, "reports/kge_eval.json")
