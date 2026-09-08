import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";

import { store } from "../../store";
import ContentExperimentsPage from "./ContentExperimentsPage";

// Các service kéo axiosClient -> axios (ESM) mà jest của CRA không transform.
jest.mock("../../services/contentExperimentService", () => ({
  contentExperimentService: {
    list: jest.fn().mockResolvedValue([]),
    create: jest.fn(),
    setEnabled: jest.fn(),
    stats: jest.fn(),
  },
}));
jest.mock("../../services/courseService", () => ({
  courseService: { getList: jest.fn().mockResolvedValue({ data: { items: [] } }) },
}));
jest.mock("../../services/courseVersionService", () => ({
  courseVersionService: { list: jest.fn() },
}));

/**
 * Một lỗi lúc render làm React unmount cả cây và TRẮNG toàn bộ trang admin —
 * không toast, không log. Đã mất một buổi vì đúng chuyện đó ở modal phiên bản
 * nội dung, nên trang này có test render ngay từ đầu.
 */
describe("ContentExperimentsPage", () => {
  it("render được và không trắng trang khi chưa có đợt nào", async () => {
    render(
      <Provider store={store}>
        <ContentExperimentsPage />
      </Provider>
    );

    expect(
      screen.getByText("A/B test nội dung khoá học")
    ).toBeInTheDocument();
    await waitFor(() =>
      expect(screen.getByText("Chưa có đợt nào.")).toBeInTheDocument()
    );
  });

  /** Danh sách khoá trả về hình dạng khác thì cũng không được hạ cả trang. */
  it("chịu được course list không có items", async () => {
    const { courseService } = jest.requireMock("../../services/courseService");
    courseService.getList.mockResolvedValueOnce({});

    render(
      <Provider store={store}>
        <ContentExperimentsPage />
      </Provider>
    );

    await waitFor(() =>
      expect(screen.getByText("— chọn khoá —")).toBeInTheDocument()
    );
  });
});
