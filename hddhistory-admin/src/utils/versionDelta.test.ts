import { deltaOf, formatDelta, formatMetric } from "./versionDelta";

describe("deltaOf", () => {
  it("tô xanh khi đi đúng hướng tốt của chỉ số", () => {
    expect(deltaOf(62, 55, 1)).toEqual({ value: 7, tone: "good" });
    expect(deltaOf(3, 9, -1)).toEqual({ value: -6, tone: "good" });
  });

  it("tô đỏ khi đi ngược hướng tốt", () => {
    expect(deltaOf(48, 55, 1)).toEqual({ value: -7, tone: "bad" });
    expect(deltaOf(12, 9, -1)).toEqual({ value: 3, tone: "bad" });
  });

  it("chỉ số không có hướng thì không bao giờ tô màu", () => {
    expect(deltaOf(90, 60, 0)).toEqual({ value: 30, tone: "neutral" });
  });

  it("bằng nhau là trung tính, không phải tốt", () => {
    expect(deltaOf(55, 55, 1)).toEqual({ value: 0, tone: "neutral" });
  });

  it("thiếu số một bên thì không bịa ra chênh lệch", () => {
    expect(deltaOf(null, 55, 1)).toBeNull();
    expect(deltaOf(55, null, 1)).toBeNull();
    expect(deltaOf(undefined, 55, 1)).toBeNull();
  });
});

describe("formatMetric", () => {
  it("null hiện gạch ngang, KHÔNG hiện 0", () => {
    expect(formatMetric(null, "%", 1)).toBe("—");
    expect(formatMetric(undefined, "%", 1)).toBe("—");
    expect(formatMetric(0, "%", 1)).toBe("0,0%");
  });

  it("giữ đúng số chữ số thập phân của chỉ số", () => {
    expect(formatMetric(42, " giây", 0)).toBe("42 giây");
    expect(formatMetric(4.25, "/5", 1)).toBe("4,3/5");
  });
});

describe("formatDelta", () => {
  it("nói rõ khi bằng bản mốc thay vì in +0", () => {
    expect(formatDelta({ value: 0, tone: "neutral" }, "%", 1)).toBe("bằng bản mốc");
  });

  it("dùng dấu trừ thật cho số âm", () => {
    expect(formatDelta({ value: -7, tone: "bad" }, "%", 1)).toBe("−7,0%");
    expect(formatDelta({ value: 7, tone: "good" }, "%", 1)).toBe("+7,0%");
  });

  it("không có chênh lệch thì không in gì", () => {
    expect(formatDelta(null, "%", 1)).toBe("");
  });
});
