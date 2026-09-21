import pytest
from src.step2_load_neo4j import get_driver, load_triples, count_nodes_and_relationships


@pytest.fixture()
def driver():
    d = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    yield d
    with d.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    d.close()


def test_load_triples_creates_expected_nodes_and_relationships(driver):
    triples = [
        {"head_qid": "Q1", "head_label": "A", "tail_qid": "Q2", "tail_label": "B",
         "relation_pid": "P1", "relation_label": "rel"},
    ]
    result = load_triples(driver, triples)
    assert result["triples_loaded"] == 1
    counts = count_nodes_and_relationships(driver)
    assert counts["node_count"] == 2
    assert counts["relationship_count"] == 1
