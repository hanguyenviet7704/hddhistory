from src.step6_generate_question import (
    call_llm, validate_question,
)


class _FakeContent:
    def __init__(self, text):
        self.text = text


class _FakeMessage:
    def __init__(self, text):
        self.content = [_FakeContent(text)]


class _FakeMessages:
    def __init__(self, text):
        self._text = text

    def create(self, **kwargs):
        return _FakeMessage(self._text)


class _FakeClient:
    def __init__(self, text):
        self.messages = _FakeMessages(text)


def test_call_llm_returns_text_from_client():
    client = _FakeClient('{"question": "test?"}')
    result = call_llm("prompt bất kỳ", client=client)
    assert "question" in result


def test_validate_question_accepts_when_years_and_anchors_match():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Đảng Cộng sản Việt Nam được thành lập năm nào?",
        "answer": "1930",
        "explanation": "Theo dữ kiện, Đảng Cộng sản Việt Nam có thời điểm là 1930.",
        "anchors": ["Đảng Cộng sản Việt Nam"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is True


def test_validate_question_rejects_year_outside_context():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Sự kiện này có liên quan gì đến năm 1945?",
        "answer": "Có",
        "explanation": "Năm 1945 là một mốc quan trọng khác.",
        "anchors": ["Đảng Cộng sản Việt Nam"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is False
    assert "1945" in result["reason"]


def test_validate_question_rejects_anchor_outside_context():
    facts = [{"subject": "Đảng Cộng sản Việt Nam", "relation": "thời điểm",
              "object": "1930", "source_pid": "P585"}]
    question = {
        "question": "Ai thành lập tổ chức này?",
        "answer": "Hồ Chí Minh",
        "explanation": "Không có trong dữ kiện.",
        "anchors": ["Hồ Chí Minh"],
    }
    result = validate_question(question, facts)
    assert result["accepted"] is False


def test_validate_question_rejects_when_no_anchor_declared():
    facts = [{"subject": "A", "relation": "r", "object": "B", "source_pid": "P1"}]
    question = {"question": "?", "answer": "B", "explanation": "vì A r B", "anchors": []}
    result = validate_question(question, facts)
    assert result["accepted"] is False
