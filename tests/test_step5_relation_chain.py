import pytest
from src.step2_load_neo4j import get_driver, load_triples
from src.step5_relation_chain import get_relation_chain, format_context


def test_format_context_numbers_each_fact():
    facts = [
        {"subject": "Hồ Chí Minh", "relation": "tham gia",
         "object": "Đảng Cộng sản Việt Nam", "source_pid": "P710"},
        {"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
         "object": "1930", "source_pid": "P585"},
    ]
    context = format_context(facts)
    assert "1. Hồ Chí Minh --tham gia--> Đảng Cộng sản Việt Nam (nguồn: P710)" in context
    assert "2. Đảng Cộng sản Việt Nam --thời điểm--> 1930 (nguồn: P585)" in context


# CẢNH BÁO: fixture này xoá TOÀN BỘ node/relationship trong Neo4j, kể cả dữ
# liệu thật đã nạp cho các Bước sau — chạy `pytest` (không chỉ file này) sau
# khi đã nạp dữ liệu thật sẽ xoá nó; nạp lại bằng `python -m src.step2_load_neo4j`
# nếu cần.
@pytest.fixture()
def driver_with_seed_graph():
    d = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    load_triples(d, [
        {"head_qid": "Q1", "head_label": "A", "tail_qid": "Q2", "tail_label": "B",
         "relation_pid": "P1", "relation_label": "quan hệ 1"},
        {"head_qid": "Q2", "head_label": "B", "tail_qid": "Q3", "tail_label": "C",
         "relation_pid": "P2", "relation_label": "quan hệ 2"},
    ])
    yield d
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    d.close()


def test_get_relation_chain_returns_multi_hop_facts(driver_with_seed_graph):
    facts = get_relation_chain(driver_with_seed_graph, "Q1", max_hops=2, limit=20)
    subjects_objects = {(f["subject"], f["object"]) for f in facts}
    assert ("A", "B") in subjects_objects
    assert ("B", "C") in subjects_objects
