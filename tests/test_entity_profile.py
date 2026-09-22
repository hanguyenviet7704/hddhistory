import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from entity_profile import build_profile, find_entity, format_profile

DATASET = {
    "periods": [
        {"id": "p05_tran", "name": "Nhà Trần", "start": "1225", "end": "1400"},
        {"id": "p04_ly", "name": "Nhà Lý", "start": "1009", "end": "1225"},
    ],
    "sources": [
        {"id": "s_dvsktt", "title": "Đại Việt sử ký toàn thư", "note": "Ngô Sĩ Liên"},
    ],
    "entities": [
        {"id": "tran_hung_dao", "type": "figure", "name": "Trần Hưng Đạo",
         "period_id": "p05_tran", "description": "Tổng chỉ huy quân đội Đại Việt.",
         "source_ids": ["s_dvsktt"]},
        {"id": "nha_tran", "type": "organization", "name": "Nhà Trần",
         "period_id": "p05_tran", "description": "Triều đại 1225–1400.",
         "source_ids": ["s_dvsktt"]},
        {"id": "hich_tuong_si", "type": "organization", "name": "Hịch tướng sĩ",
         "period_id": "p05_tran", "description": "Văn bản hiệu triệu tướng sĩ.",
         "source_ids": ["s_dvsktt"]},
        {"id": "tran_quoc_toan", "type": "figure", "name": "Trần Quốc Toản",
         "period_id": "p05_tran", "description": "Thiếu niên anh hùng.",
         "source_ids": ["s_dvsktt"]},
        {"id": "ly_thai_to", "type": "figure", "name": "Lý Thái Tổ",
         "period_id": "p04_ly", "description": "Lập nhà Lý.",
         "source_ids": ["s_dvsktt"]},
    ],
    "relations": [
        {"head": "tran_hung_dao", "relation": "served", "tail": "nha_tran",
         "source_ids": ["s_dvsktt"]},
        {"head": "tran_hung_dao", "relation": "authored", "tail": "hich_tuong_si",
         "source_ids": ["s_dvsktt"]},
        {"head": "tran_quoc_toan", "relation": "served", "tail": "nha_tran",
         "source_ids": ["s_dvsktt"]},
        {"head": "nha_tran", "relation": "succeeded", "tail": "ly_thai_to",
         "source_ids": ["s_dvsktt"]},
    ],
}


def test_find_entity_by_exact_name():
    assert find_entity(DATASET, "Trần Hưng Đạo")["id"] == "tran_hung_dao"


def test_find_entity_by_id():
    assert find_entity(DATASET, "tran_hung_dao")["id"] == "tran_hung_dao"


def test_find_entity_ignores_diacritics_and_case():
    assert find_entity(DATASET, "tran hung dao")["id"] == "tran_hung_dao"


def test_find_entity_returns_none_when_unknown():
    assert find_entity(DATASET, "Không Có Ai") is None


def test_build_profile_collects_outgoing_relations():
    profile = build_profile(DATASET, "tran_hung_dao")
    outgoing = {(r["relation"], r["target"]["name"]) for r in profile["outgoing"]}
    assert outgoing == {("served", "Nhà Trần"), ("authored", "Hịch tướng sĩ")}


def test_build_profile_collects_incoming_relations():
    profile = build_profile(DATASET, "nha_tran")
    incoming = {(r["source"]["name"], r["relation"]) for r in profile["incoming"]}
    assert incoming == {("Trần Hưng Đạo", "served"), ("Trần Quốc Toản", "served")}


def test_build_profile_same_period_excludes_self_and_other_periods():
    profile = build_profile(DATASET, "tran_hung_dao")
    names = {e["name"] for e in profile["same_period"]}
    assert "Trần Hưng Đạo" not in names
    assert "Lý Thái Tổ" not in names
    assert names == {"Nhà Trần", "Hịch tướng sĩ", "Trần Quốc Toản"}


def test_build_profile_resolves_period_and_sources():
    profile = build_profile(DATASET, "tran_hung_dao")
    assert profile["period"]["name"] == "Nhà Trần"
    assert [s["title"] for s in profile["sources"]] == ["Đại Việt sử ký toàn thư"]


def test_build_profile_raises_on_unknown_id():
    try:
        build_profile(DATASET, "khong_ton_tai")
    except KeyError:
        return
    raise AssertionError("build_profile phải báo lỗi khi id không tồn tại")


def test_format_profile_shows_name_period_and_relations():
    text = format_profile(build_profile(DATASET, "tran_hung_dao"))
    assert "TRẦN HƯNG ĐẠO" in text
    assert "Nhà Trần (1225–1400)" in text
    assert "Tổng chỉ huy quân đội Đại Việt." in text
    assert "Hịch tướng sĩ" in text
    assert "Đại Việt sử ký toàn thư" in text


def test_format_profile_translates_known_relation_labels():
    text = format_profile(build_profile(DATASET, "tran_hung_dao"))
    assert "phục vụ → Nhà Trần" in text
    assert "soạn → Hịch tướng sĩ" in text


def test_format_profile_falls_back_to_raw_label_for_unknown_relation():
    dataset = {
        **DATASET,
        "relations": [{"head": "tran_hung_dao", "relation": "quan_he_la",
                       "tail": "nha_tran", "source_ids": ["s_dvsktt"]}],
    }
    text = format_profile(build_profile(dataset, "tran_hung_dao"))
    assert "quan_he_la → Nhà Trần" in text


def test_format_profile_includes_kge_section_only_when_given():
    profile = build_profile(DATASET, "tran_hung_dao")
    assert "theo KGE" not in format_profile(profile)
    with_kge = format_profile(profile, similar=[("Nhà Trần", 0.87), ("Hịch tướng sĩ", 0.55)])
    assert "theo KGE" in with_kge
    assert "0.87" in with_kge
