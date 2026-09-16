import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";

import { store } from "../../store";
import CourseVersionsModal from "./CourseVersionsModal";

// courseService kéo axiosClient -> axios (ESM) mà jest của CRA không transform;
// mock để test đứng đúng chỗ cần test là render.
jest.mock("../../services/courseService", () => ({
  courseService: { exportCourseFull: jest.fn() },
}));

// Modal gọi API ngay khi mở; ở đây chỉ cần nó không nổ lúc render, nên service
// trả về hình dạng đúng như API thật.
jest.mock("../../services/courseVersionService", () => ({
  courseVersionService: {
    list: jest.fn().mockResolvedValue({
      versions: [],
      currentTag: null,
      nextTag: "v1.0.0",
      pending: { added: [], changed: [], removed: [], total: 0 },
    }),
    create: jest.fn(),
    setCurrent: jest.fn(),
    remove: jest.fn(),
    backfill: jest.fn(),
    audioCoverage: jest.fn(),
    dubMissing: jest.fn(),
    dubStatus: jest.fn(),
  },
}));

const VERSION = {
  _id: "v1",
  tag: "v1.0.1",
  note: null,
  entityCounts: { lessons: 1, keypoints: 2, learningItems: 3 },
  isCurrent: true,
};

const renderModal = () =>
  render(
    <Provider store={store}>
      <CourseVersionsModal
        open
        courseId="68c0000000000000000000c1"
        courseTitle="Khoá có tag"
        onClose={() => undefined}
      />
    </Provider>
  );

/**
 * Tái hiện "bấm nút tag là trắng màn": trắng màn = lỗi lúc render, nên chỉ cần
 * render modal ở trạng thái mở là đủ để lỗi lộ ra.
 */
describe("CourseVersionsModal", () => {
  it("renders when opened", () => {
    render(
      <Provider store={store}>
        <CourseVersionsModal
          open
          courseId="68c0000000000000000000c1"
          courseTitle='Cách nói "không" lành mạnh'
          onClose={() => undefined}
        />
      </Provider>
    );

    expect(screen.getByText("Phiên bản nội dung")).toBeInTheDocument();
  });

  /**
   * Cú trắng màn thật: nếu `nextTag` không có (API bọc response, hoặc shape
   * đổi) thì `setTag(undefined)` và render sau đó gọi `tag.trim()` -> TypEror
   * -> React unmount cả cây -> trắng toàn bộ trang admin. Một field thiếu
   * không được phép hạ cả trang.
   */
  it("survives a payload with no nextTag instead of blanking the page", async () => {
    const { courseVersionService } = jest.requireMock(
      "../../services/courseVersionService"
    );
    courseVersionService.list.mockResolvedValueOnce({
      versions: [],
      currentTag: null,
      pending: { added: [], changed: [], removed: [], total: 0 },
    });

    render(
      <Provider store={store}>
        <CourseVersionsModal
          open
          courseId="68c0000000000000000000c1"
          courseTitle="Khoá thiếu nextTag"
          onClose={() => undefined}
        />
      </Provider>
    );

    await waitFor(() =>
      expect(screen.getByText("Phiên bản nội dung")).toBeInTheDocument()
    );
    expect(screen.getByPlaceholderText("v1.0.1")).toHaveValue("");
  });

  // CRA bật `resetMocks`, nên implementation bị xoá giữa các test — dựng lại ở
  // đây thay vì trong một test rồi trông chờ test sau vẫn còn.
  const withTag = () => {
    const { courseVersionService } = jest.requireMock(
      "../../services/courseVersionService"
    );
    courseVersionService.list.mockResolvedValue({
      versions: [VERSION],
      currentTag: "v1.0.1",
      nextTag: "v1.0.2",
      pending: { added: [], changed: [], removed: [], total: 0 },
    });
    courseVersionService.audioCoverage.mockResolvedValue({
      tag: "v1.0.1",
      courseId: "c1",
      versionId: "v1",
      langs: ["vi", "en", "zh", "ja", "ko"],
      summary: { done: 3, stale: 1, missing: 2, none: 4 },
      complete: false,
      keypoints: [
        {
          keypointId: "k1",
          title: { vi: "Hiểu về mâu thuẫn" },
          statuses: { vi: "stale" },
          missing: { vi: 2 },
        },
      ],
    });

    return courseVersionService;
  };

  /**
   * Câu hỏi cả tính năng này sinh ra để trả lời: tag nào có audio, tag nào
   * không. Phải đọc được ngay trên bảng, không phải bấm vào mới biết.
   */
  it("shows how many cells a tag is short of audio", async () => {
    withTag();

    renderModal();

    await waitFor(() => expect(screen.getByText("thiếu 3 ô")).toBeInTheDocument());
  });

  it("names the keypoints to fix, not just the count", async () => {
    const courseVersionService = withTag();

    renderModal();

    const chip = await screen.findByText("thiếu 3 ô");
    fireEvent.click(chip);

    expect(await screen.findByText("Hiểu về mâu thuẫn")).toBeInTheDocument();
    expect(screen.getByText("Ghi bù phần thiếu")).toBeInTheDocument();
    expect(courseVersionService.audioCoverage).toHaveBeenCalled();
  });
});
