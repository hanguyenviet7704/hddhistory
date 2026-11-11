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
      "hddhistory://open/habit"
    );
  });

  it("gắn tham số của màn", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "paywall", { variant: "full" })
    ).toBe("https://meup.training/open/paywall?variant=full");
  });

  it("bỏ tham số rỗng thay vì gửi khoá trống", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "course-roadmap", { courseId: "  " })
    ).toBe("https://meup.training/open/course-roadmap");
  });

  it("gắn UTM vào link web, giữ thứ tự source→medium→campaign→content→term", () => {
    expect(
      buildDeeplinkUrl(
        DEEPLINK_WEB_BASE,
        "paywall",
        {},
        {
          source: "zalo",
          medium: "push",
          campaign: "tet-2027",
          content: "banner-a",
          term: "hoc_tieng_anh",
        }
      )
    ).toBe(
      "https://meup.training/open/paywall?utm_source=zalo&utm_medium=push&utm_campaign=tet-2027&utm_content=banner-a&utm_term=hoc_tieng_anh"
    );
  });

  it("KHÔNG gắn UTM vào link hddhistory:// — người dùng đã ở trong app, không có kênh nào để quy", () => {
    expect(
      buildDeeplinkUrl(
        DEEPLINK_APP_BASE,
        "paywall",
        { variant: "full" },
        { source: "zalo", campaign: "tet-2027" }
      )
    ).toBe("hddhistory://open/paywall?variant=full");
  });

  it("bỏ UTM rỗng", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "habit", {}, { source: "  ", medium: "" })
    ).toBe("https://meup.training/open/habit");
  });

  it("encode giá trị có ký tự đặc biệt", () => {
    expect(
      buildDeeplinkUrl(DEEPLINK_WEB_BASE, "paywall", {}, { campaign: "hè & thu" })
    ).toBe("https://meup.training/open/paywall?utm_campaign=h%C3%A8%20%26%20thu");
  });
});
