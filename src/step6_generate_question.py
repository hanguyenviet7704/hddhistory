# %% [markdown]
# ## Bước 6 — Sinh câu hỏi có kiểm soát
#
# Prompt chỉ chứa các fact đã trích ở Bước 5 — mô hình không được dùng kiến
# thức nền riêng của nó. Sau khi mô hình trả lời, một bước kiểm tra tự động
# đối chiếu lại với chính các fact đầu vào theo 2 tiêu chí:
#
# 1. **Năm**: mọi số 4 chữ số xuất hiện trong câu hỏi/đáp án/giải thích phải
#    có mặt trong các fact đầu vào (trích bằng regex `\b\d{4}\b`, đối chiếu
#    tập hợp).
# 2. **Anchor**: mô hình phải tự khai những thực thể nó dùng (`anchors`), và
#    mọi anchor đó phải là một `subject`/`object` có thật trong fact đầu vào.
#
# Lý do dùng "anchor" thay vì cố dò tên riêng bằng regex trên toàn câu: tiếng
# Việt không viết hoa tên riêng theo quy tắc chặt như tiếng Anh, dò bằng regex
# dễ sai (bỏ sót hoặc bắt nhầm từ thường). Bắt mô hình khai báo anchor rồi đối
# chiếu tập hợp là một kiểm tra đáng tin cậy hơn nhiều.

# %%
import re
import json


def build_prompt(context: str) -> str:
    return (
        "Dưới đây là các dữ kiện lịch sử đã được xác minh:\n\n"
        f"{context}\n\n"
        "Hãy soạn một câu hỏi kiểm tra kiến thức dựa CHỈ trên các dữ kiện trên. "
        "Không dùng bất kỳ tên riêng hay năm nào không xuất hiện trong dữ kiện. "
        "Trả về đúng định dạng JSON, không thêm chữ nào khác:\n"
        '{"question": "...", "answer": "...", "explanation": "...", '
        '"anchors": ["..."]}'
    )


def call_llm(prompt: str, client=None) -> str:
    """Gọi Claude API, trả về text thô của phản hồi.
    `client` truyền vào để test bằng fake client, không gọi mạng thật."""
    if client is None:
        import anthropic
        client = anthropic.Anthropic()
    message = client.messages.create(
        model="claude-sonnet-5",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    return message.content[0].text


def extract_years(text: str) -> set:
    """Trích mọi số 4 chữ số trong text."""
    return set(re.findall(r"\b\d{4}\b", text))


def extract_allowed_years(facts: list) -> set:
    """Trích mọi năm 4 chữ số xuất hiện trong facts đầu vào."""
    allowed = set()
    for fact in facts:
        allowed |= extract_years(fact["subject"]) | extract_years(fact["object"])
    return allowed


def extract_allowed_names(facts: list) -> set:
    """Trích mọi subject/object xuất hiện trong facts đầu vào."""
    names = set()
    for fact in facts:
        names.add(fact["subject"])
        names.add(fact["object"])
    return names


def validate_question(question_json: dict, facts: list) -> dict:
    """Kiểm tra câu hỏi: (1) mọi năm phải có trong ngữ cảnh, (2) mọi anchor
    mô hình khai phải là một thực thể có thật trong facts đầu vào."""
    full_text = " ".join([
        question_json.get("question", ""),
        question_json.get("answer", ""),
        question_json.get("explanation", ""),
    ])
    used_years = extract_years(full_text)
    allowed_years = extract_allowed_years(facts)
    unmatched_years = used_years - allowed_years
    if unmatched_years:
        return {"accepted": False,
                "reason": f"Năm không có trong ngữ cảnh: {unmatched_years}"}

    allowed_names = extract_allowed_names(facts)
    anchors = set(question_json.get("anchors", []))
    if not anchors:
        return {"accepted": False, "reason": "Không có anchor nào được khai báo"}
    unmatched_anchors = anchors - allowed_names
    if unmatched_anchors:
        return {"accepted": False,
                "reason": f"Anchor không có trong ngữ cảnh: {unmatched_anchors}"}

    return {"accepted": True, "reason": None}


# %% [markdown]
# ### Ví dụ minh hoạ (chạy thật)
#
# _(Chưa chạy thật — cần biến môi trường `ANTHROPIC_API_KEY`. Sau khi có key, chạy `python -m src.step6_generate_question` với ngữ cảnh đầy đủ để lấy ví dụ "accepted", rồi rút bớt 1 fact và chạy lại để lấy ví dụ "rejected"; dán cả hai kết quả thật vào đây.)_

# %%
if __name__ == "__main__":
    from src.step2_load_neo4j import get_driver
    from src.step5_relation_chain import get_relation_chain, format_context

    driver = get_driver("bolt://localhost:7687", "neo4j", "kg-research-pw")
    example_qid = "Q8740"
    facts = get_relation_chain(driver, example_qid, max_hops=2, limit=20)
    driver.close()

    context = format_context(facts)
    prompt = build_prompt(context)
    raw_response = call_llm(prompt)
    question_json = json.loads(raw_response)
    result = validate_question(question_json, facts)
    print(json.dumps(question_json, ensure_ascii=False, indent=2))
    print(result)
