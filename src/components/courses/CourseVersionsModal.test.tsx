import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
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
  },
}));

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
});
