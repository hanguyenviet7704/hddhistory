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
  });

  mocked.getUsers.mockResolvedValue({
    range,
    compareRange,
    totals: { active: 1515, new: 1008, returning: 507 },
    previousTotals: { active: 1302, new: 921, returning: 381 },
    daily: [{ date: "2026-08-01", active: 180, new: 120 }],
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
        label: "Mở lộ trình",
        event: "roadmap_scr_view",
        users: 802,
        events: 5120,
        previousUsers: 700,
      },
    ],
    topCourses: [
      {
        id: "c1",
        name: "Ngừng chỉ đọc, hãy bắt đầu nhớ lại",
        users: 144,
        events: 1820,
      },
    ],
    topSkills: [{ id: "s1", name: "Learn Better", users: 402, events: 5120 }],
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

  it("says a too-young cohort has no D7 number instead of showing 0%", async () => {
    renderPage(<DashboardUsers />);

    expect(await screen.findByText("1.515")).toBeInTheDocument();
    // The unmeasurable D7 renders as an em dash in the stat card…
    expect(screen.getAllByText("—").length).toBeGreaterThan(0);
    // …and spells it out in the per-version table.
    expect(screen.getAllByText("chưa đủ dữ liệu").length).toBeGreaterThan(0);
    expect(screen.getByText("Chưa có cohort đủ tuổi")).toBeInTheDocument();
  });

  it("renders session totals and the peak-hour reading", async () => {
    renderPage(<DashboardSessions />);

    expect(await screen.findByText("3.686")).toBeInTheDocument();
    expect(screen.getByText("70,3%")).toBeInTheDocument();
    expect(screen.getByText(/Cao điểm lúc 22h/)).toBeInTheDocument();
  });

  it("renders the onboarding funnel with the biggest drop named", async () => {
    renderPage(<DashboardOnboarding />);

    // The stat card and the funnel's first step both show the entry count.
    expect((await screen.findAllByText("908")).length).toBe(2);
    expect(screen.getAllByText("Màn chào mừng").length).toBeGreaterThan(0);
    expect(screen.getByText(/Mất 145 người/)).toBeInTheDocument();
  });

  it("renders learning milestones and the top course list", async () => {
    renderPage(<DashboardLearning />);

    expect(await screen.findByText("802")).toBeInTheDocument();
    expect(screen.getByText("Mở lộ trình")).toBeInTheDocument();
    expect(
      screen.getByText("Ngừng chỉ đọc, hãy bắt đầu nhớ lại")
    ).toBeInTheDocument();
  });
});
