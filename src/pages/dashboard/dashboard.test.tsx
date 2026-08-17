import React from "react";
import { render, screen } from "@testing-library/react";

// React Router 7 is ESM-only and CRA's Jest cannot resolve it, so the two hooks
// and the one component these pages use are stubbed instead. `virtual: true`
// keeps Jest from trying to resolve the real package at all.
jest.mock(
  "react-router-dom",
  () => ({
    useSearchParams: () => [new URLSearchParams(), jest.fn()],
    useLocation: () => ({ search: "", pathname: "/dashboard" }),
    Link: ({ children, to, ...rest }: any) => (
      <a href={String(to)} {...rest}>
        {children}
      </a>
    ),
  }),
  { virtual: true }
);

// A factory mock, not an automock: automocking still loads the real module,
// which pulls in axios — ESM-only in v1, and CRA's Jest does not transform it.
// The spies are created inside the factory because `jest.mock` is hoisted above
// every declaration in this file.
jest.mock("../../services/dashboardService", () => ({
  dashboardService: {
    getOverview: jest.fn(),
    getUsers: jest.fn(),
    getSessions: jest.fn(),
    getOnboarding: jest.fn(),
    getLearning: jest.fn(),
  },
}));

import DashboardLearning from "./DashboardLearning";
import DashboardOnboarding from "./DashboardOnboarding";
import DashboardOverview from "./DashboardOverview";
import DashboardSessions from "./DashboardSessions";
import DashboardUsers from "./DashboardUsers";

const range = {
  from: "2026-08-01T00:00:00.000Z",
  to: "2026-08-07T23:59:59.999Z",
  days: 7,
};
const compareRange = {
  from: "2026-07-25T00:00:00.000Z",
  to: "2026-07-31T23:59:59.999Z",
  days: 7,
};

const retention = [
  { offset: 1, cohortUsers: 968, retainedUsers: 191, rate: 0.197 },
  // Deliberately unmeasurable: the pages must say so rather than print 0%.
  { offset: 7, cohortUsers: 0, retainedUsers: 0, rate: null },
];

const funnelStep = {
  event: "obd_welcome_scr_view",
  users: 763,
  passRate: 0.84,
  dropUsers: 145,
  dropRate: 0.16,
};

const mocked = jest.requireMock("../../services/dashboardService")
  .dashboardService as Record<string, jest.Mock>;

const renderPage = (ui: React.ReactElement) => render(ui);

beforeEach(() => {
  jest.clearAllMocks();

  mocked.getOverview.mockResolvedValue({
    range,
    compareRange,
    users: {
      active: 1515,
      new: 1008,
      returning: 507,
      previous: { active: 1302, new: 921, returning: 381 },
    },
    retention,
    sessions: { total: 3686, engagementRate: 0.703, previousTotal: 3180 },
    onboarding: {
      started: 908,
      completed: 670,
      completionRate: 0.738,
      biggestDrop: funnelStep,
    },
    learning: {
      roadmapOpened: 802,
      lessonCompleted: 514,
      topCourse: {
        id: "c1",
        name: "Ngừng chỉ đọc, hãy bắt đầu nhớ lại",
        users: 144,
        events: 1820,
      },
      topSkill: { id: "s1", name: "Learn Better", users: 402, events: 5120 },
    },
    peakHours: [
      { hour: 22, sessions: 80, events: 1600 },
      { hour: 10, sessions: 61, events: 1100 },
      { hour: 11, sessions: 58, events: 1050 },
    ],
    versionDepth: {
      versions: [
        {
          appVersion: "1.4.2",
          sessions: 900,
          users: 400,
          sessionMedianMs: 126000, // 2p 6s
          lessonsPerSession: 0.6,
          completionRate: 0.67,
          sessionsPerUserPerDay: 1.56,
        },
        {
          appVersion: "1.4.4",
          sessions: 700,
          users: 380,
          sessionMedianMs: 222000, // 3p 42s
          lessonsPerSession: 1.11,
          completionRate: 0.8,
          sessionsPerUserPerDay: 1.41,
        },
      ],
      deltas: {
        sessionDurationPct: 0.76,
        lessonsPerSessionPct: 0.85,
        completionRatePoints: 0.13,
        sessionsPerUserPerDayPct: -0.1,
        from: "1.4.2",
        to: "1.4.4",
      },
    },
  });

  mocked.getUsers.mockResolvedValue({
    range,
    compareRange,
    totals: { active: 1515, new: 1008, returning: 507 },
    previousTotals: { active: 1302, new: 921, returning: 381 },
    daily: [{ date: "2026-08-01", active: 180, new: 120 }],
    dailyByPlatform: [
      { date: "2026-08-01", platform: "ios", users: 110 },
      { date: "2026-08-01", platform: "android", users: 70 },
    ],
    activeWindows: {
      dau: 200,
      wau: 776,
      mau: 1407,
      mauAtStart: 403,
      stickiness: 0.1421,
      dauDate: "2026-08-09",
    },
    retentionByPlatform: [
      {
        platform: "ios",
        points: [
          { offset: 1, cohortUsers: 500, retainedUsers: 126, rate: 0.252 },
        ],
      },
      {
        platform: "android",
        points: [
          { offset: 1, cohortUsers: 468, retainedUsers: 44, rate: 0.095 },
        ],
      },
    ],
    demographics: {
      byCountry: [{ name: "Việt Nam", value: 1171 }],
      byAge: [{ name: "18-24", value: 373 }],
      hasCountryData: true,
      hasAgeData: true,
    },
    retention,
    retentionByAppVersion: [
      { appVersion: "1.4.4", points: retention },
      {
        appVersion: "1.4.3",
        points: [
          { offset: 1, cohortUsers: 430, retainedUsers: 88, rate: 0.205 },
          { offset: 7, cohortUsers: 402, retainedUsers: 21, rate: 0.053 },
        ],
      },
    ],
    byPlatform: [{ name: "android", value: 902 }],
    byAppVersion: [{ name: "1.4.4", value: 640 }],
  });

  mocked.getSessions.mockResolvedValue({
    range,
    compareRange,
    totals: {
      sessions: 3686,
      engagedSessions: 2591,
      engagementRate: 0.703,
      avgDurationMs: 254000,
      avgEvents: 18.4,
      avgScreens: 6.2,
      activeUsers: 1515,
      sessionsPerUser: 2.43,
    },
    previousTotals: null,
    daily: [{ date: "2026-08-01", sessions: 480, engagedSessions: 330 }],
    hourly: Array.from({ length: 24 }, (_, hour) => ({
      hour,
      sessions: hour === 22 ? 90 : 10,
      events: hour === 22 ? 1600 : 100,
    })),
    depthBuckets: [{ from: 1, to: 1, sessions: 402 }],
    durations: {
      medianMs: 167000, // 2p 47s
      p25Ms: 17000, // 17s
      p75Ms: 736000, // 12p 16s
      engagedMedianMs: 177000, // 2p 57s
      longSessionRate: 0.19,
      bounceRate: 0.29,
    },
    byWeekday: [
      { weekday: 5, medianMs: 213000, sessions: 431 }, // Thứ 5 — 3p 33s
      { weekday: 3, medianMs: 208000, sessions: 380 },
    ],
    byAppVersion: [
      { appVersion: "1.4.4", medianMs: 224000, sessions: 300 },
      { appVersion: "1.4.3", medianMs: 197000, sessions: 280 },
    ],
    heatmap: {
      all: [
        { weekday: 6, hour: 17, users: 75 },
        { weekday: 2, hour: 9, users: 12 },
      ],
      learning: [{ weekday: 6, hour: 21, users: 30 }],
    },
  });

  mocked.getOnboarding.mockResolvedValue({
    range,
    compareRange,
    started: 908,
    completed: 670,
    completionRate: 0.738,
    previous: { started: 812, completed: 570, completionRate: 0.702 },
    steps: [
      {
        event: "obd_intro1_scr_view",
        users: 908,
        passRate: 1,
        dropUsers: 0,
        dropRate: null,
      },
      funnelStep,
    ],
    biggestDrop: funnelStep,
  });

  mocked.getLearning.mockResolvedValue({
    range,
    compareRange,
    milestones: [
      {
        key: "roadmapOpened",
        label: "Xem lộ trình",
        event: "roadmap_scr_view",
        users: 802,
        events: 5120,
        previousUsers: 700,
        passRate: 1,
        byPlatform: [
          { name: "ios", value: 645 },
          { name: "android", value: 157 },
        ],
      },
      {
        key: "keypointRead",
        label: "Bắt đầu đọc keypoint",
        event: "keypoint_read_scr_view",
        users: 680,
        events: 4010,
        previousUsers: 610,
        passRate: 0.8479,
        byPlatform: [
          { name: "ios", value: 553 },
          { name: "android", value: 127 },
        ],
      },
    ],
    engagement: {
      screenViews: 45455,
      previousScreenViews: 14845,
      keypointCompletions: 2038,
      keypointCompletionUsers: 514,
    },
    heroCourse: {
      id: "c9",
      name: "How memory works",
      users: 320,
      events: 13154,
    },
    topCourses: [
      {
        id: "c1",
        name: "Ngừng chỉ đọc, hãy bắt đầu nhớ lại",
        users: 144,
        events: 1820,
      },
    ],
    topSkills: [{ id: "s1", name: "Learn Better", users: 529, events: 5120 }],
    courseRankings: [
      {
        key: "firstChoice",
        label: "Khoá học đầu tiên user chọn",
        hint: "Khoá được chọn ở bước cuối onboarding",
        event: "obd_course_select",
        rows: [
          { id: "c2", name: "Make smarter decisions", users: 74, events: 74 },
        ],
      },
      {
        key: "completed",
        label: "Hoàn thành cao nhất",
        hint: "Xếp theo lượt hoàn thành bài",
        event: "keypoint_complete_scr_view",
        rows: [
          {
            id: "c1",
            name: "Stop rereading, start recalling",
            users: 78,
            events: 210,
          },
        ],
      },
    ],
    byAge: [
      {
        age: "18-24",
        users: 297,
        interested: [
          {
            id: "c1",
            name: "Stop rereading, start recalling",
            users: 43,
            events: 43,
          },
        ],
        completed: [
          { id: "c3", name: "Read people like a book", users: 28, events: 28 },
        ],
      },
      {
        age: "25-34",
        users: 158,
        interested: [],
        completed: [],
      },
    ],
    daily: [{ date: "2026-08-01", keypointCompleted: 88, lessonCompleted: 60 }],
  });
});

describe("Dashboard pages", () => {
  it("renders the weekly report with its headline numbers", async () => {
    renderPage(<DashboardOverview />);

    // Twice by design: once as the figure, once inside the sentence that reads
    // the card out ("1.515 người hoạt động trong kỳ…").
    expect((await screen.findAllByText("1.515")).length).toBe(2);
    expect(screen.getByText("3.686")).toBeInTheDocument();
    expect(screen.getByText("19,7%")).toBeInTheDocument();
    expect(
      screen.getByText(/Ngừng chỉ đọc, hãy bắt đầu nhớ lại/)
    ).toBeInTheDocument();
  });

  it("compares session depth across app versions", async () => {
    renderPage(<DashboardOverview />);

    expect(await screen.findByText("Độ sâu mỗi phiên học")).toBeInTheDocument();
    expect(screen.getByText("Số bài hoàn thành / phiên")).toBeInTheDocument();
    // A rate's change is reported in points, never as a percent of a percent.
    expect(screen.getByText("↑ 13 điểm")).toBeInTheDocument();
    // Fewer sessions per day alongside longer ones is a good outcome, so the
    // fall must not be painted as a regression.
    expect(screen.getByText("↓ 10%")).toHaveClass("text-emerald-700");
  });

  it("says a too-young cohort has no D7 number instead of showing 0%", async () => {
    renderPage(<DashboardUsers />);

    expect(await screen.findByText("1.515")).toBeInTheDocument();
    // The unmeasurable D7 renders as an em dash in the stat card…
    expect(screen.getAllByText("—").length).toBeGreaterThan(0);
    // …and spells it out in the per-version table.
    expect(screen.getAllByText("chưa đủ dữ liệu").length).toBeGreaterThan(0);
    expect(screen.getByText("Chưa có cohort đủ tuổi")).toBeInTheDocument();
  });

  it("renders the rolling DAU / WAU / MAU cards", async () => {
    renderPage(<DashboardUsers />);

    expect(await screen.findByText("1.407")).toBeInTheDocument(); // MAU
    expect(screen.getByText("776")).toBeInTheDocument(); // WAU
    expect(screen.getByText("14,2%")).toBeInTheDocument(); // độ dính
    expect(screen.getByText(/Đầu kỳ 403/)).toBeInTheDocument();
  });

  it("offers the retention curve split by platform and app version", async () => {
    renderPage(<DashboardUsers />);

    expect(
      await screen.findByRole("button", { name: "Theo nền tảng" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Theo bản app" })
    ).toBeInTheDocument();
  });

  it("renders the demographics section", async () => {
    renderPage(<DashboardUsers />);

    expect(await screen.findByText("Việt Nam")).toBeInTheDocument();
    expect(screen.getByText("18-24")).toBeInTheDocument();
  });

  it("renders session totals and the peak-hour reading", async () => {
    renderPage(<DashboardSessions />);

    expect(await screen.findByText("3.686")).toBeInTheDocument();
    expect(screen.getByText("70,3%")).toBeInTheDocument();
    expect(screen.getByText(/Cao điểm lúc 22h/)).toBeInTheDocument();
  });

  it("renders session length as percentiles, not an average", async () => {
    renderPage(<DashboardSessions />);

    expect(await screen.findByText("2p 47s")).toBeInTheDocument(); // trung vị
    expect(screen.getByText("17s – 12p 16s")).toBeInTheDocument(); // P25–P75
    expect(screen.getByText("2p 57s")).toBeInTheDocument(); // engaged median
    expect(screen.getByText("19%")).toBeInTheDocument(); // phiên dài
    expect(screen.getByText(/29% phiên chỉ ghé dưới 30 giây/)).toBeInTheDocument();
  });

  it("ranks weekdays and app versions by median session length", async () => {
    renderPage(<DashboardSessions />);

    // "Thứ 5" labels both the duration bar and a heatmap row, hence findAll.
    expect((await screen.findAllByText("Thứ 5")).length).toBeGreaterThan(0);
    expect(screen.getByText("3p 33s")).toBeInTheDocument();
    expect(screen.getByText("1.4.4")).toBeInTheDocument();
  });

  it("renders the weekday-by-hour heatmap and its mode toggle", async () => {
    renderPage(<DashboardSessions />);

    expect(await screen.findByText(/Đậm nhất:/)).toBeInTheDocument();
    expect(screen.getByText("Thứ 6 17:00")).toBeInTheDocument();
    expect(screen.getByText(/75 người/)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Học bài" })
    ).toBeInTheDocument();
  });

  it("renders the onboarding funnel with the biggest drop named", async () => {
    renderPage(<DashboardOnboarding />);

    // The stat card and the funnel's first step both show the entry count.
    expect((await screen.findAllByText("908")).length).toBe(2);
    expect(screen.getAllByText("Màn chào mừng").length).toBeGreaterThan(0);
    expect(screen.getByText(/Mất 145 người/)).toBeInTheDocument();
  });

  it("renders the learning funnel with its per-platform split", async () => {
    renderPage(<DashboardLearning />);

    expect(await screen.findByText("802")).toBeInTheDocument();
    expect(screen.getByText("Xem lộ trình")).toBeInTheDocument();
    // The split is what turns "we lost people" into "we lost them on Android".
    expect(screen.getByText("iOS 645 · Android 157")).toBeInTheDocument();
    expect(screen.getByText("84,8%")).toBeInTheDocument();
  });

  it("renders engagement volume and the hero course", async () => {
    renderPage(<DashboardLearning />);

    expect(await screen.findByText("45.455")).toBeInTheDocument();
    expect(screen.getByText("2.038")).toBeInTheDocument();
    expect(screen.getByText(/Bởi 514 người dùng/)).toBeInTheDocument();
    expect(screen.getByText("How memory works")).toBeInTheDocument();
  });

  it("renders every course ranking and the age tabs", async () => {
    renderPage(<DashboardLearning />);

    expect(
      await screen.findByText("Khoá học đầu tiên user chọn")
    ).toBeInTheDocument();
    expect(screen.getByText("Hoàn thành cao nhất")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /25-34/ })).toBeInTheDocument();
    // First age group is selected by default, so its lists are on screen.
    expect(screen.getByText("Quan tâm nhất (vào đọc bài)")).toBeInTheDocument();
  });
});
