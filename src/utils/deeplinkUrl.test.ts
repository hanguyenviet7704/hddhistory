import {
  DEEPLINK_APP_BASE,
  DEEPLINK_WEB_BASE,
  buildDeeplinkUrl,
} from "./deeplinkUrl";

describe("buildDeeplinkUrl", () => {
  it("dựng link web cho màn không tham số", () => {
    expect(buildDeeplinkUrl(DEEPLINK_WEB_BASE, "habit", {})).toBe(
      "https://meup.training/open/habit"
    );
  });

  it("dựng link trong app cùng một khoá", () => {
    expect(buildDeeplinkUrl(DEEPLINK_APP_BASE, "habit", {})).toBe(
      "meup://open/habit"
    );
  });

  it("gắn tham số và nhãn campaign", () => {
    expect(
      buildDeeplinkUrl(
        DEEPLINK_WEB_BASE,
        "paywall",
        { variant: "full" },
        "tet-2027"
      )
    ).toBe("https://meup.training/open/paywall?variant=full&c=tet-2027");
  });

  it("bỏ tham số rỗng thay vì gửi khoá trống", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "course-roadmap", { courseId: "  " })
    ).toBe("https://meup.training/open/course-roadmap");
  });

  it("encode giá trị có ký tự đặc biệt", () => {
    expect(buildDeeplinkUrl(DEEPLINK_WEB_BASE, "paywall", {}, "hè & thu")).toBe(
      "https://meup.training/open/paywall?c=h%C3%A8%20%26%20thu"
    );
  });
});
