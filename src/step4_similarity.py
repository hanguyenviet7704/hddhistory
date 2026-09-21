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
# Chạy thật `python -m src.step4_similarity`: huấn luyện lại TransE như
# Bước 3 (toàn bộ `data/raw/triples.csv` — 997 triple duy nhất / 1009 thực
# thể, 100 epoch, `random_seed=42`, cùng model chất lượng thấp với
# MRR≈0.0218 đã báo cáo ở Bước 3), lấy 20 thực thể đầu tiên theo
# `entity_to_id` để vẽ PCA 2D (lưu tại `reports/embedding_plot.png`), và
# tính `most_similar` của thực thể đầu tiên so với toàn bộ 1009 thực thể.
#
# **Cặp có liên hệ trực tiếp trên đồ thị** — `Chiến tranh Việt Nam` và
# `Hoa Kỳ` (nối trực tiếp bằng cạnh `P710 người tham gia` — dòng 7 của
# `data/raw/triples.csv`):
#
# - `cosine("Chiến tranh Việt Nam", "Hoa Kỳ")` = **-0.1363**
#
# **Cặp không liên quan** — `Chiến tranh Việt Nam` và
# `Cúp bóng chuyền nam vô địch châu Á 2012` (hai thực thể không chia sẻ
# cạnh nào trong toàn bộ CSV, thuộc hai miền chủ đề khác nhau — chiến
# tranh vs. thể thao):
#
# - `cosine("Chiến tranh Việt Nam", "Cúp bóng chuyền nam vô địch châu Á 2012")` = **-0.0359**
#
# **Nhận xét (trung thực, không cherry-pick):** kết quả **không** ủng hộ
# giả thuyết "cặp có liên hệ thì similarity cao hơn cặp không liên quan" —
# thực tế ngược lại: cặp có cạnh nối trực tiếp (`Chiến tranh Việt Nam` –
# `Hoa Kỳ`) cho cosine **thấp hơn** (-0.1363, âm nhiều hơn) so với cặp hoàn
# toàn không liên quan (-0.0359). Cả hai giá trị đều âm và gần 0, không có
# một hướng lệch dương rõ ràng nào phản ánh cấu trúc đồ thị. Đây là một kết
# quả tiêu cực/không thuyết phục, nhưng phù hợp và có thể giải thích được
# bằng những gì Bước 3 đã báo cáo: đồ thị quá thưa (997 triple / 1009 thực
# thể, trung bình ~2 triple mỗi thực thể — bản thân `Chiến tranh Việt Nam`
# chỉ xuất hiện trong 27 dòng, hầu hết cùng một loại quan hệ `P710`), 100
# epoch là rất ít, và TransE (baseline) trên một tập test MRR≈0.0218 gần
# như ngẫu nhiên (so với random-guess trên 1009 thực thể, MRR ngẫu nhiên kỳ
# vọng ≈ 1/1009 ≈ 0.001, nên 0.0218 nhìn thô có "hơn ngẫu nhiên" nhưng vẫn
# rất yếu để suy ra semantics đáng tin). Kết luận trung thực: ở baseline
# này, cosine similarity giữa embedding **không** phản ánh đáng tin cậy mối
# quan hệ thật trên đồ thị — pipeline tính similarity/PCA hoạt động đúng về
# mặt kỹ thuật, nhưng chất lượng embedding đầu vào (đã được Bước 3 nêu rõ là
# thấp) không đủ để similarity mang ý nghĩa ngữ nghĩa. Scatter PCA ở
# `reports/embedding_plot.png` (20 thực thể đầu, phần lớn là các mốc thời
# gian dạng `YYYY-01-01T00:00:00Z` cùng hai thực thể `10th`/`11th Vietnam
# Film Festival`) cũng không cho thấy cụm chủ đề rõ ràng — cùng một quan
# sát. `most_similar` của thực thể đầu tiên
# (`-0110-01-01T00:00:00Z`, một mốc thời gian) trả về top-5 gồm cả một sự
# kiện lịch sử (`Trận Ngọc Hồi – Đống Đa`, 0.437) lẫn các mốc thời gian
# khác — không có mẫu hình rõ ràng nào để kết luận thêm.

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
