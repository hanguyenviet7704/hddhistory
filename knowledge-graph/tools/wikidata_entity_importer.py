"""Tool nhập thực thể vào data/vn_history/vn_history_seed.json từ Wikidata.

Thuần code, KHÔNG gọi AI — chỉ tra cứu Wikidata qua API/SPARQL công khai rồi
suy luận type/period bằng luật cố định. Chạy được độc lập, không cần hỏi Claude.

Cách dùng:
    python tools/wikidata_entity_importer.py --names "Nguyễn Bỉnh Khiêm" "Mạc Thái Tổ"
    python tools/wikidata_entity_importer.py --qids Q3919391 Q736284
    python tools/wikidata_entity_importer.py --names "Nguyễn Bỉnh Khiêm" --dry-run

Kết quả được ghi thẳng vào data/vn_history/vn_history_seed.json (trừ khi
--dry-run). Xem lại bằng `git diff` như mọi thay đổi khác — không có bước
"duyệt" riêng, vì mọi thứ đã ở trong git.

GIỚI HẠN ĐÃ BIẾT (không cố che giấu):
- Suy luận `type` chỉ dựa trên một bảng tra P31 cố định, nhiều lớp Wikidata
  không nằm trong bảng sẽ ra `type: "unknown"` — cần bạn tự sửa tay.
- Suy luận `period_id` chỉ hoạt động khi thời kỳ có mốc năm CN rõ ràng
  (period `p03` trở đi); giai đoạn Hồng Bàng/Bắc thuộc (p01, p02) có mốc mờ
  ("TCN", "truyền thuyết") nên luôn để `period_id: None`, cần gán tay.
- Không tự tạo quan hệ (relations) — Wikidata có nhiều thuộc tính liên quan
  nhưng chọn đúng loại quan hệ ngữ nghĩa (participated_in/served/founded...)
  là việc cần con người quyết định, không suy luận máy móc được đáng tin cậy.
- Wikidata không phủ hết chi tiết lịch sử Việt Nam — nhiều nhân vật/sự kiện
  sẽ không tìm thấy hoặc dữ liệu rất sơ sài.
"""
import argparse
import json
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DATASET_PATH = Path(__file__).resolve().parent.parent / "data" / "vn_history" / "vn_history_seed.json"

WIKIDATA_SEARCH_API = "https://www.wikidata.org/w/api.php"
WIKIDATA_SPARQL_ENDPOINT = "https://query.wikidata.org/sparql"
USER_AGENT = "hddhistory-vn-history-importer/0.1"

# P31 (instance of) QID -> type nội bộ. Chỉ các lớp phổ biến nhất; QID không có
# trong bảng này sẽ ra type "unknown", không đoán bừa.
TYPE_MAP = {
    "Q5": "figure",  # human
    "Q1656682": "event",  # event
    "Q178561": "event",  # battle
    "Q198": "event",  # war
    "Q124734": "event",  # rebellion
    "Q3839081": "event",  # coup d'état
    "Q2334719": "event",  # military offensive
    "Q43229": "organization",  # organization
    "Q7278": "organization",  # political party
    "Q192909": "organization",  # dynasty
    "Q3624078": "organization",  # sovereign state
    "Q6256": "organization",  # country
    "Q486972": "place",  # human settlement
    "Q2221906": "place",  # geographic location
    "Q515": "place",  # city
    "Q3957": "place",  # town
}


def slugify_vi(name: str) -> str:
    """Chuyển tên tiếng Việt có dấu thành slug ASCII dùng làm id, ví dụ
    'Nguyễn Bỉnh Khiêm' -> 'nguyen_binh_khiem'."""
    name = name.replace("đ", "d").replace("Đ", "D")
    nfkd = unicodedata.normalize("NFKD", name)
    ascii_str = nfkd.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", ascii_str).strip("_").lower()
    return slug


def _http_get_json(url: str, max_retries: int = 6) -> dict:
    """GET + parse JSON, với retry lùi dần khi bị Wikidata rate-limit (429)
    hoặc lỗi tạm thời phía server (503)."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code in (429, 503) and attempt < max_retries - 1:
                wait = 2 ** (attempt + 1)
                print(f"  (bị giới hạn tần suất HTTP {e.code}, đợi {wait}s rồi thử lại...)")
                time.sleep(wait)
                continue
            raise


def search_qid_by_name(name: str, language: str = "vi") -> list:
    """Tìm QID theo tên qua Wikidata search API. Trả về list candidate
    {"qid", "label", "description"}, top kết quả đứng đầu."""
    params = {
        "action": "wbsearchentities",
        "search": name,
        "language": language,
        "format": "json",
        "limit": 5,
    }
    url = f"{WIKIDATA_SEARCH_API}?{urllib.parse.urlencode(params)}"
    data = _http_get_json(url)
    candidates = []
    for item in data.get("search", []):
        candidates.append({
            "qid": item["id"],
            "label": item.get("label", ""),
            "description": item.get("description", ""),
        })
    return candidates


def fetch_entities_data(qids: list) -> dict:
    """Chạy SPARQL lấy label/description/instance-of/ngày tháng cho danh
    sách QID. Trả về dict qid -> {"label", "description", "instance_of":
    [qid...], "birth": str|None, "death": str|None, "point_in_time": str|None,
    "start": str|None, "end": str|None}."""
    values_clause = " ".join(f"wd:{q}" for q in qids)
    query = f"""
    SELECT ?item ?itemLabel ?itemDescription ?instanceOf
           ?birth ?death ?pointInTime ?start ?end WHERE {{
      VALUES ?item {{ {values_clause} }}
      OPTIONAL {{ ?item wdt:P31 ?instanceOf }}
      OPTIONAL {{ ?item wdt:P569 ?birth }}
      OPTIONAL {{ ?item wdt:P570 ?death }}
      OPTIONAL {{ ?item wdt:P585 ?pointInTime }}
      OPTIONAL {{ ?item wdt:P580 ?start }}
      OPTIONAL {{ ?item wdt:P582 ?end }}
      SERVICE wikibase:label {{ bd:serviceParam wikibase:language "vi,en". }}
    }}
    """
    url = f"{WIKIDATA_SPARQL_ENDPOINT}?{urllib.parse.urlencode({'query': query, 'format': 'json'})}"
    data = _http_get_json(url)
    bindings = data["results"]["bindings"]

    result = {}
    for b in bindings:
        qid = b["item"]["value"].rsplit("/", 1)[-1]
        entry = result.setdefault(qid, {
            "label": b.get("itemLabel", {}).get("value", ""),
            "description": b.get("itemDescription", {}).get("value", ""),
            "instance_of": set(),
            "birth": None, "death": None, "point_in_time": None,
            "start": None, "end": None,
        })
        if "instanceOf" in b:
            entry["instance_of"].add(b["instanceOf"]["value"].rsplit("/", 1)[-1])
        for field, key in [("birth", "birth"), ("death", "death"),
                            ("pointInTime", "point_in_time"),
                            ("start", "start"), ("end", "end")]:
            if field in b and entry[key] is None:
                entry[key] = b[field]["value"]
    for entry in result.values():
        entry["instance_of"] = sorted(entry["instance_of"])
    return result


def infer_type(instance_of_qids: list) -> str:
    """Suy luận type nội bộ từ danh sách P31. 'unknown' nếu không khớp gì."""
    for qid in instance_of_qids:
        if qid in TYPE_MAP:
            return TYPE_MAP[qid]
    return "unknown"


def _extract_year(date_str) -> int:
    """Lấy năm CN từ chuỗi ISO date Wikidata (vd '1858-08-31T00:00:00Z') ->
    int, hoặc None nếu không parse được hoặc là năm TCN (âm)."""
    if not date_str:
        return None
    m = re.match(r"^(-?\d+)-\d{2}-\d{2}", date_str)
    if not m:
        return None
    year = int(m.group(1))
    return year if year > 0 else None


def infer_period(entry: dict, periods: list) -> str:
    """Suy luận period_id từ point_in_time/start/death/birth (theo thứ tự
    ưu tiên đó). Chỉ khớp được với các thời kỳ có mốc năm CN rõ ràng (p03 trở
    đi trong dataset hiện tại). Trả về None nếu không đủ tin cậy để suy luận.

    Với nhân vật, ưu tiên năm mất hơn năm sinh: nhiều nhân vật lịch sử Việt
    Nam sinh ở một thời kỳ nhưng hoạt động/nổi bật ở thời kỳ sau (ví dụ sinh
    trước 1858 nhưng tham gia kháng Pháp sau 1858) — năm mất thường phản ánh
    đúng thời kỳ gắn với nhân vật đó hơn. Đây vẫn chỉ là suy đoán, không thay
    thế việc rà soát tay."""
    year = (_extract_year(entry.get("point_in_time"))
            or _extract_year(entry.get("start"))
            or _extract_year(entry.get("death"))
            or _extract_year(entry.get("birth")))
    if year is None:
        return None
    for period in periods:
        start_m = re.match(r"^(\d+)$", str(period.get("start", "")).strip())
        end_raw = str(period.get("end", "")).strip()
        end_m = re.match(r"^(\d+)$", end_raw)
        if not start_m:
            continue
        start_year = int(start_m.group(1))
        end_year = int(end_m.group(1)) if end_m else 9999  # "nay" -> mở
        if start_year <= year <= end_year:
            return period["id"]
    return None


def unique_id(base_slug: str, existing_ids: set) -> str:
    if base_slug not in existing_ids:
        return base_slug
    i = 2
    while f"{base_slug}_{i}" in existing_ids:
        i += 1
    return f"{base_slug}_{i}"


def load_dataset(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save_dataset(path: Path, data: dict) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def build_entity(qid: str, entry: dict, periods: list, existing_ids: set) -> dict:
    entity_type = infer_type(entry["instance_of"])
    period_id = infer_period(entry, periods)
    name = entry["label"] or qid
    base_slug = slugify_vi(name) or qid.lower()
    entity_id = unique_id(base_slug, existing_ids)

    description = entry["description"] or "(Wikidata không có mô tả — cần bổ sung tay.)"
    entity = {
        "id": entity_id,
        "type": entity_type,
        "name": name,
        "period_id": period_id,
        "description": description,
        "note": f"Nhập tự động từ Wikidata ({qid}) — CẦN RÀ SOÁT: mô tả/loại/thời kỳ có thể chưa chính xác hoặc thiếu.",
        "source_ids": ["s_wikidata"],
    }
    return entity, qid


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--names", nargs="+", default=[], help="Tên thực thể cần tra (tìm QID tự động)")
    parser.add_argument("--qids", nargs="+", default=[], help="QID Wikidata trực tiếp (bỏ qua bước tìm tên)")
    parser.add_argument("--dry-run", action="store_true", help="Chỉ in kết quả, không ghi file")
    args = parser.parse_args()

    if not args.names and not args.qids:
        parser.error("Cần ít nhất --names hoặc --qids")

    dataset = load_dataset(DATASET_PATH)
    existing_ids = {e["id"] for e in dataset["entities"]}
    existing_source_ids = {s["id"] for s in dataset["sources"]}

    qids_to_fetch = list(args.qids)
    unresolved_names = []
    for i, name in enumerate(args.names):
        if i > 0:
            time.sleep(2.5)  # tránh bị Wikidata rate-limit khi tra nhiều tên liên tiếp
        print(f"Đang tìm QID cho '{name}'...")
        candidates = search_qid_by_name(name)
        if not candidates:
            unresolved_names.append(name)
            print(f"  KHÔNG TÌM THẤY: '{name}' — bỏ qua.")
            continue
        top = candidates[0]
        print(f"  -> chọn {top['qid']} ({top['label']}: {top['description']})")
        if len(candidates) > 1:
            others = ", ".join(f"{c['qid']} ({c['label']})" for c in candidates[1:])
            print(f"     (còn {len(candidates) - 1} kết quả khác nếu chọn sai: {others})")
        qids_to_fetch.append(top["qid"])

    if not qids_to_fetch:
        print("Không có QID nào để tra cứu. Dừng.")
        sys.exit(1)

    print(f"\nĐang tra cứu {len(qids_to_fetch)} QID trên Wikidata...")
    entries = fetch_entities_data(qids_to_fetch)

    new_entities = []
    flagged = []
    for qid in qids_to_fetch:
        entry = entries.get(qid)
        if entry is None:
            print(f"  {qid}: không có dữ liệu trả về, bỏ qua.")
            continue
        entity, _ = build_entity(qid, entry, dataset["periods"], existing_ids)
        existing_ids.add(entity["id"])
        new_entities.append(entity)
        if entity["type"] == "unknown" or entity["period_id"] is None:
            flagged.append(entity["id"])

    print(f"\n=== Kết quả: {len(new_entities)} thực thể ===")
    for e in new_entities:
        marker = " [CẦN RÀ SOÁT]" if e["id"] in flagged else ""
        print(f"  {e['id']}: type={e['type']} period={e['period_id']} name={e['name']}{marker}")

    if unresolved_names:
        print(f"\nTên không tìm thấy trên Wikidata: {unresolved_names}")

    if args.dry_run:
        print("\n--dry-run: chưa ghi file.")
        return

    if not new_entities:
        print("\nKhông có thực thể mới để ghi.")
        return

    dataset["entities"].extend(new_entities)
    if any(e["source_ids"] == ["s_wikidata"] for e in new_entities) and "s_wikidata" not in existing_source_ids:
        dataset["sources"].append({
            "id": "s_wikidata",
            "title": "Wikidata",
            "note": "Cơ sở tri thức mở, dữ liệu nhập tự động qua tools/wikidata_entity_importer.py — cần đối chiếu lại với nguồn sử học trước khi dùng chính thức.",
        })
    save_dataset(DATASET_PATH, dataset)
    print(f"\nĐã ghi {len(new_entities)} thực thể vào {DATASET_PATH}.")
    print(f"{len(flagged)} thực thể cần rà soát tay (type='unknown' hoặc period_id=None): {flagged}")
    print("Xem lại bằng: git diff -- data/vn_history/vn_history_seed.json")


if __name__ == "__main__":
    main()
