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
# Thực thể chọn: **Q8740** — "Chiến tranh Việt Nam" (xuất hiện ở 27 dòng làm
# head trong `data/raw/triples.csv`, nên có nhiều quan hệ trong Neo4j). Chạy
# `python -m src.step5_relation_chain` trên dữ liệu thật (1017 nút / 1000
# cạnh) cho kết quả sau (20 fact đầu, `max_hops=2`, nguyên văn output thật):
#
# ```
# 1. Chiến tranh Việt Nam --người tham gia--> Hoa Kỳ (nguồn: P710)
# 2. Sự kiện Tết Mậu Thân --người tham gia--> Hoa Kỳ (nguồn: P710)
# 3. Trận Đồi Thịt Băm --người tham gia--> Hoa Kỳ (nguồn: P710)
# 4. Trận Long Tân --người tham gia--> Hoa Kỳ (nguồn: P710)
# 5. Trận Ia Đrăng --người tham gia--> Hoa Kỳ (nguồn: P710)
# 6. Chiến tranh Đông Dương lần thứ ba --người tham gia--> Hoa Kỳ (nguồn: P710)
# 7. Chiến dịch Cedar Falls --người tham gia--> Hoa Kỳ (nguồn: P710)
# 8. Chiến dịch Đắk Tô-Tân Cảnh (1967) --người tham gia--> Hoa Kỳ (nguồn: P710)
# 9. Trận Nam Đông --người tham gia--> Hoa Kỳ (nguồn: P710)
# 10. Trận Đồng Xoài --người tham gia--> Hoa Kỳ (nguồn: P710)
# 11. Chiến dịch Masher --người tham gia--> Hoa Kỳ (nguồn: P710)
# 12. Vụ tập kích Sơn Tây --người tham gia--> Hoa Kỳ (nguồn: P710)
# 13. Trận Mậu Thân tại Huế --người tham gia--> Hoa Kỳ (nguồn: P710)
# 14. Battle of Hill 881 --người tham gia--> Hoa Kỳ (nguồn: P710)
# 15. Operation Dewey Canyon --người tham gia--> Hoa Kỳ (nguồn: P710)
# 16. Trận Bình Giã --người tham gia--> Hoa Kỳ (nguồn: P710)
# 17. Operation Crimp --người tham gia--> Hoa Kỳ (nguồn: P710)
# 18. Operation Francis Marion --người tham gia--> Hoa Kỳ (nguồn: P710)
# 19. Chiến dịch Speedy Express --người tham gia--> Hoa Kỳ (nguồn: P710)
# 20. Trận Tầm Bó --người tham gia--> Hoa Kỳ (nguồn: P710)
# ```
#
# Vì truy vấn đi hai chiều (`-[:RELATION*1..2]-`, không chỉ theo hướng cạnh),
# hop thứ hai từ "Chiến tranh Việt Nam" đi tới "Hoa Kỳ" rồi vòng ra các thực
# thể khác cũng có cạnh `P710 (người tham gia)` tới "Hoa Kỳ" — nên 20 fact
# đầu (không có `ORDER BY`, giới hạn bởi `LIMIT`) đều xoay quanh các trận
# đánh/chiến dịch có Hoa Kỳ tham gia, chứ không lộ ra các quan hệ 1-hop khác
# (`vị trí`, `ngày bắt đầu`, ...) của chính Chiến tranh Việt Nam — những quan
# hệ đó vẫn có trong Neo4j nhưng bị Cypher trả về sau trong danh sách không
# sắp thứ tự này.

# %%
if __name__ == "__main__":
    from src.step2_load_neo4j import get_driver

    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    # Q8740 = "Chiến tranh Việt Nam": xuất hiện ở 27 dòng làm head trong
    # data/raw/triples.csv, nên có nhiều quan hệ thật trong Neo4j để minh hoạ.
    example_qid = "Q8740"
    facts = get_relation_chain(driver, example_qid, max_hops=2, limit=20)
    print(format_context(facts))
    driver.close()
