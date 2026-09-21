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
