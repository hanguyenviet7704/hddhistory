"""Ghép 6 file src/stepN_*.py thành một notebook báo cáo duy nhất."""
from pathlib import Path

import jupytext
import nbformat

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
#
# **Lưu ý trước khi chạy:** ô thiết lập ngay dưới đây đưa cwd của kernel về
# thư mục gốc repo (Jupyter mặc định đặt cwd là thư mục chứa notebook —
# `notebooks/` — nên các đường dẫn tương đối như `data/raw/triples.csv` và các
# import `from src...` trong các Bước dưới sẽ lỗi, hoặc tệ hơn là âm thầm ghi
# file mới vào `notebooks/data/`, `notebooks/reports/`, nếu không có ô này).
# Ngoài ra, chạy lại ô thật của Bước 1 sẽ truy vấn Wikidata trực tiếp và có
# thể trả về số liệu khác với số liệu đã ghi lại trong văn bản của báo cáo này
# (Wikidata là dữ liệu sống, thay đổi theo thời gian).

# %%
import os
import sys
from pathlib import Path

if "__file__" in dir():
    _repo_root = Path(__file__).resolve().parent.parent
elif Path.cwd().name == "notebooks":
    _repo_root = Path.cwd().parent
else:
    _repo_root = Path.cwd()

os.chdir(_repo_root)
sys.path.insert(0, str(_repo_root))
print(f"cwd đã đặt về: {Path.cwd()}")
'''

FOOTER = '''# %% [markdown]
# ## Kết luận và hướng tiếp theo
#
# Pipeline đã chứng minh được trên dữ liệu Wikidata công khai, ở mức độ chính
# xác như sau — **Bước 1–5 đã chạy thật đầu-cuối trên dữ liệu thật**: trích
# subgraph từ Wikidata → lưu vào Neo4j → huấn luyện KGE (TransE, PyKEEN) →
# tính độ tương đồng cosine + trực quan hoá embedding → trích chuỗi quan hệ
# multi-hop làm ngữ cảnh. **Bước 6** (sinh câu hỏi có kiểm soát) có phần
# validate-tự-động đã cài đặt và có unit test (5/5 test giả lập bằng fake
# client, không gọi mạng thật) xác nhận đúng logic chặn năm/anchor không có
# trong ngữ cảnh — nhưng lượt chạy thật sinh câu hỏi từ một entity thật, gọi
# Claude qua API, vẫn **đang chờ** biến môi trường `ANTHROPIC_API_KEY` (chưa
# có trên máy thực hiện báo cáo này). Nói cách khác, cơ chế validate đã được
# *xây và kiểm chứng bằng test*, nhưng chưa được *chứng minh chặn được nội
# dung sai lệch trên một câu trả lời thật* — hai việc khác nhau, và báo cáo
# này chỉ khẳng định việc đã làm được.
#
# ### Đối chiếu tiêu chí nghiệm thu
#
# - **Đã đạt:** subgraph Wikidata được trích và nạp thành công vào Neo4j
#   (1017 node / 1000 quan hệ, Bước 1–2); KGE được huấn luyện thật bằng
#   PyKEEN/TransE với số liệu MRR/Hits@k thật đo trên tập test (Bước 3);
#   chuỗi quan hệ multi-hop được trích thật từ Neo4j làm ngữ cảnh cho Bước 6
#   (Bước 5).
# - **Đã đạt nhưng ra kết quả tiêu cực một cách trung thực (không phải lỗi
#   pipeline):** phần so sánh độ tương đồng ở Bước 4 — cặp thực thể có cạnh
#   nối trực tiếp trên đồ thị (`Chiến tranh Việt Nam` – `Hoa Kỳ`) lại có
#   cosine similarity **thấp hơn** cặp hoàn toàn không liên quan, ngược với
#   giả thuyết ngây thơ "liên quan thì similarity cao hơn". Bước 4 đã tự giải
#   thích nguyên nhân (đồ thị thưa, nhiều thực thể timestamp degree-1, ít
#   epoch) — xem mục "Ví dụ minh hoạ" của Bước 4 ở trên, không diễn giải lại
#   ở đây.
# - **Đang chờ:** ví dụ chạy thật của Bước 6 (sinh câu hỏi qua Claude API và
#   validate) — như đã nêu ngay trên, chờ `ANTHROPIC_API_KEY`.
#
# Bước tiếp theo (ngoài phạm vi báo cáo này): áp dụng đúng pipeline này lên dữ
# liệu lịch sử Việt Nam tự soạn giai đoạn 1858–1945, rồi triển khai tầng lập
# lịch (Adaptive Microlearning Scheduling), tầng tương tác và tầng cập nhật
# đánh giá (Relational Diffusion) theo 5 tầng giáo viên đã giao.
'''


KERNELSPEC = {
    "display_name": "Python 3 (.venv)",
    "language": "python",
    "name": "python3",
}


def build_combined(root: Path) -> str:
    parts = [HEADER]
    for rel_path in STEP_FILES:
        parts.append((root / rel_path).read_text(encoding="utf-8"))
    parts.append(FOOTER)
    return "\n\n".join(parts)


def build_notebook(root: Path) -> None:
    """Ghép các file src/stepN_*.py, viết ra bản trung gian
    (notebooks/_combined_report.py, gitignored) rồi chuyển thẳng thành
    notebooks/01_pipeline_report.ipynb qua jupytext API (thay vì gọi CLI
    riêng), gắn kernelspec thật trong cùng một bước — để lệnh này là nguồn
    duy nhất tạo ra notebook cuối cùng, không cần fix-up thủ công sau đó.
    """
    combined = build_combined(root)
    combined_path = root / "notebooks" / "_combined_report.py"
    combined_path.write_text(combined, encoding="utf-8")
    print(f"Đã ghép vào {combined_path}")

    nb = jupytext.reads(combined, fmt="py:percent")
    nb.metadata["kernelspec"] = KERNELSPEC

    out_path = root / "notebooks" / "01_pipeline_report.ipynb"
    nbformat.write(nb, out_path)
    print(f"Đã sinh notebook (kèm kernelspec) tại {out_path}")


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    build_notebook(root)
