import React from "react";
import { render, screen, waitFor } from "@testing-library/react";

import VersionComparisonPage from "./VersionComparisonPage";

/**
 * Mock ở tầng `axiosClient`, KHÔNG mock service.
 *
 * Có hai lý do và lý do thứ hai mới là lý do thật. Thứ nhất, axiosClient kéo
 * axios (ESM) mà jest của CRA không transform. Thứ hai: meup-api bọc mọi
 * response trong `{statusCode, message, data}`, và mock service trả thẳng
 * payload sẽ khiến test XANH trong khi bug phong bì vẫn còn sống — đúng cái
 * đã xảy ra ở modal phiên bản nội dung và làm TRẮNG cả trang admin. Mock ở
 * đây thì `unwrapApi` trong service chạy thật.
 */
const mockGet = jest.fn();
jest.mock("../../services/axiosClient", () => ({
  __esModule: true,
  default: { get: (...args: unknown[]) => mockGet(...args) },
}));

const envelope = (data: unknown) => ({
  data: { statusCode: 200, message: "Success", data },
});

const version = (over: Record<string, unknown> = {}) => ({
  tag: "v1.0.0",
  versionId: "v1",
  note: "bản đầu",
  createdAt: "2026-09-01T00:00:00.000Z",
  publishedAt: "2026-09-01T00:00:00.000Z",
  live: false,
  windows: [{ from: "2026-09-01T00:00:00.000Z", to: "2026-09-05T00:00:00.000Z" }],
  liveDays: 4,
  lessons: 2,
  cards: 4,
  metrics: {
    pub: "2026-09-01T00:00:00.000Z",
    cardSec: 42,
    lessonMin: 5,
    done: 66.7,
    courseDone: 40,
    csat: 4.3,
    bugs: 7,
  },
  sample: { courseViewers: 100, lessonOpeners: 180, csatResponses: 25 },
  retention: [
    { lessonIndex: 1, lessonId: "l1", pct: 80 },
    { lessonIndex: 2, lessonId: "l2", pct: 40 },
  ],
  depth: [
    { lessonIndex: 1, lessonId: "l1", pct: 75, openers: 100, cards: 2 },
    { lessonIndex: 2, lessonId: "l2", pct: 30, openers: 80, cards: 2 },
  ],
  dropOffLessons: [2],
  ...over,
});

const comparison = (versions: unknown[]) => ({
  courseId: "c1",
  courseTitle: "Nền tảng Khoa học Hành vi",
  currentTag: "v1.0.1",
  generatedAt: "2026-09-09T00:00:00.000Z",
  metrics: [
    { key: "pub", group: "Phát hành", label: "Thời gian xuất bản", unit: "", dec: 0, polarity: 0, type: "date" },
    { key: "cardSec", group: "Nhịp đọc", label: "Thời gian đọc TB 1 card", unit: " giây", dec: 0, polarity: 0 },
    { key: "done", group: "Kết quả", label: "Tỉ lệ hoàn thành bài học", unit: "%", dec: 1, polarity: 1 },
    { key: "bugs", group: "Kết quả", label: "Số lượng báo lỗi", unit: " lượt", dec: 0, polarity: -1 },
  ],
  versions,
  ranges: { cardSec: { min: 38, max: 42 }, done: { min: 66.7, max: 71.2 }, bugs: { min: 3, max: 7 } },
});

const wire = (versions: unknown[]) => {
  mockGet.mockReset();
  mockGet.mockImplementation((url: string) => {
    if (url.includes("/courses")) {
      return Promise.resolve(envelope([{ id: "c1", title: "Nền tảng Khoa học Hành vi" }]));
    }

    return Promise.resolve(envelope(comparison(versions)));
  });
};

describe("VersionComparisonPage", () => {
  it("render được và bóc đúng phong bì của API", async () => {
    wire([
      version(),
      version({ tag: "v1.0.1", versionId: "v2", live: true, note: "gộp bài 2" }),
    ]);

    render(<VersionComparisonPage />);

    await waitFor(() =>
      expect(screen.getByText("So sánh phiên bản khoá học")).toBeInTheDocument(),
    );
    // Khoá lấy được từ trong phong bì -> dropdown có tên thật.
    expect(await screen.findByText("Nền tảng Khoa học Hành vi")).toBeInTheDocument();
    // Hai bản mặc định được chọn -> bảng so sánh hiện.
    expect(await screen.findByText("Bảng so sánh chỉ số")).toBeInTheDocument();
    expect(screen.getByText("Đường giữ chân toàn khoá")).toBeInTheDocument();
    expect(screen.getByText("Độ sâu theo từng bài")).toBeInTheDocument();
  });

  it("khoá mới có 1 phiên bản thì nói rõ, không trắng trang", async () => {
    wire([version()]);

    render(<VersionComparisonPage />);

    expect(
      await screen.findByText(/mới có 1 phiên bản/i),
    ).toBeInTheDocument();
    expect(screen.queryByText("Bảng so sánh chỉ số")).not.toBeInTheDocument();
  });

  it("bản chưa phát hành hiện dấu gạch chứ không hiện 0", async () => {
    wire([
      version(),
      version({ tag: "v1.0.1", versionId: "v2", live: true }),
      version({
        tag: "v1.0.2",
        versionId: "v3",
        live: false,
        publishedAt: null,
        windows: [],
        liveDays: 0,
        metrics: {
          pub: null, cardSec: null, lessonMin: null,
          done: null, courseDone: null, csat: null, bugs: null,
        },
        retention: [],
        depth: [],
        dropOffLessons: [],
      }),
    ]);

    render(<VersionComparisonPage />);

    expect(await screen.findByText("Chưa phát hành")).toBeInTheDocument();
  });

  it("API hỏng thì báo lỗi chứ không unmount cả cây", async () => {
    mockGet.mockReset();
    mockGet.mockRejectedValue(new Error("500"));

    render(<VersionComparisonPage />);

    expect(
      await screen.findByText("Không tải được danh sách khoá."),
    ).toBeInTheDocument();
  });
});
