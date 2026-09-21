from src.step1_extract_wikidata import bindings_to_triples, save_triples_csv


def test_bindings_to_triples_handles_uri_and_literal_tail():
    bindings = [
        {
            "head": {"type": "uri", "value": "http://www.wikidata.org/entity/Q10520"},
            "headLabel": {"value": "Hồ Chí Minh"},
            "relation": {"type": "uri", "value": "http://www.wikidata.org/entity/P39"},
            "relationLabel": {"value": "chức vụ"},
            "tail": {"type": "uri", "value": "http://www.wikidata.org/entity/Q1234"},
            "tailLabel": {"value": "Chủ tịch nước"},
        },
        {
            "head": {"type": "uri", "value": "http://www.wikidata.org/entity/Q10520"},
            "headLabel": {"value": "Hồ Chí Minh"},
            "relation": {"type": "uri", "value": "http://www.wikidata.org/entity/P569"},
            "relationLabel": {"value": "ngày sinh"},
            "tail": {"type": "literal", "value": "1890-05-19T00:00:00Z"},
            "tailLabel": {"value": "1890-05-19T00:00:00Z"},
        },
    ]
    triples = bindings_to_triples(bindings)
    assert triples[0]["head_qid"] == "Q10520"
    assert triples[0]["tail_qid"] == "Q1234"
    assert triples[1]["tail_qid"] == "1890-05-19T00:00:00Z"


def test_save_triples_csv_writes_header_and_rows(tmp_path):
    triples = [{
        "head_qid": "Q1", "head_label": "A", "relation_pid": "P1",
        "relation_label": "rel", "tail_qid": "Q2", "tail_label": "B",
    }]
    out = tmp_path / "triples.csv"
    save_triples_csv(triples, str(out))
    content = out.read_text(encoding="utf-8")
    assert "head_qid,head_label,relation_pid,relation_label,tail_qid,tail_label" in content
    assert "Q1,A,P1,rel,Q2,B" in content
