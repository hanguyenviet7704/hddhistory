import React, { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { ChevronDownIcon, ChevronRightIcon } from "@heroicons/react/24/outline";
import { analyticsService } from "../../../services/analyticsService";
import {
  IUserBehaviorEvent,
  IUserBehaviorSession,
} from "../../../types/interface/analytics.interface";
import {
  formatClock,
  formatDayLabel,
  formatDuration,
  summarizeParams,
} from "./behaviorFormat";

const EVENTS_PAGE_SIZE = 50;

interface SessionEventsState {
  items: IUserBehaviorEvent[];
  nextCursor: string | null;
  loading: boolean;
  error: boolean;
}

const emptyEventsState: SessionEventsState = {
  items: [],
  nextCursor: null,
  loading: false,
  error: false,
};

// Links back into the content the event happened on, using ids already carried in
// params — no extra lookup needed.
const ParamLinks = ({ params }: { params?: Record<string, any> }) => {
  if (!params) return null;
  const links: { to: string; label: string }[] = [];
  if (params.course_id) {
    links.push({ to: `/course/${params.course_id}`, label: "Course" });
  }
  if (params.lesson_id) {
    links.push({ to: `/lesson/${params.lesson_id}`, label: "Lesson" });
  }
  if (params.keypoint_id) {
    links.push({ to: `/keypoint/${params.keypoint_id}`, label: "Keypoint" });
  }
  if (!links.length) return null;

  return (
    <span className="flex items-center gap-1">
      {links.map((link) => (
        <Link
          key={link.to}
          to={link.to}
          className="rounded border border-blue-200 px-1 text-[10px] text-blue-600 hover:bg-blue-50"
        >
          {link.label}
        </Link>
      ))}
    </span>
  );
};

const EventRow = ({ event }: { event: IUserBehaviorEvent }) => {
  const [open, setOpen] = useState(false);
  const hasParams = !!event.params && Object.keys(event.params).length > 0;
  const summary = summarizeParams(event.params);

  return (
    <div className="border-t border-gray-100 first:border-t-0">
      <div className="flex items-center gap-2 px-3 py-1.5 text-sm">
        <span className="w-20 font-mono text-xs text-gray-400">
          {formatClock(event.clientTs)}
        </span>
        <span
          className={`rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase ${
            event.kind === "screen"
              ? "bg-violet-100 text-violet-700"
              : "bg-slate-100 text-slate-600"
          }`}
        >
          {event.kind}
        </span>
        <span className="font-mono text-xs text-gray-900 truncate max-w-[220px]" title={event.name}>
          {event.name}
        </span>
        <span className="flex-1 truncate text-xs text-gray-500" title={summary}>
          {summary}
        </span>
        <ParamLinks params={event.params} />
        {hasParams ? (
          <button
            type="button"
            onClick={() => setOpen((prev) => !prev)}
            className="text-xs text-blue-600 hover:text-blue-800"
          >
            {open ? "Ẩn params" : "Params"}
          </button>
        ) : null}
      </div>
      {open && hasParams ? (
        <pre className="mx-3 mb-2 max-h-60 overflow-auto rounded bg-slate-50 p-2 text-[11px] text-slate-700">
          {JSON.stringify(event.params, null, 2)}
        </pre>
      ) : null}
    </div>
  );
};

export default function SessionTimeline({
  userId,
  sessions,
  truncated,
  namePrefix,
}: {
  userId: string;
  sessions: IUserBehaviorSession[];
  truncated: boolean;
  namePrefix: string;
}) {
  const [openSessionId, setOpenSessionId] = useState<string | null>(null);
  const [eventsBySession, setEventsBySession] = useState<
    Record<string, SessionEventsState>
  >({});

  // A different name filter means the loaded events no longer match what the
  // filter promises — drop them so the next expand refetches.
  useEffect(() => {
    setEventsBySession({});
  }, [namePrefix, userId]);

  const loadEvents = useCallback(
    async (sessionId: string, cursor?: string) => {
      setEventsBySession((prev) => ({
        ...prev,
        [sessionId]: {
          ...(prev[sessionId] ?? emptyEventsState),
          loading: true,
          error: false,
        },
      }));

      try {
        const res = await analyticsService.getSessionEvents(userId, {
          sessionId,
          namePrefix: namePrefix || undefined,
          cursor,
          limit: EVENTS_PAGE_SIZE,
        });

        setEventsBySession((prev) => {
          const current = prev[sessionId] ?? emptyEventsState;
          return {
            ...prev,
            [sessionId]: {
              items: cursor
                ? [...current.items, ...(res?.items ?? [])]
                : res?.items ?? [],
              nextCursor: res?.nextCursor ?? null,
              loading: false,
              error: false,
            },
          };
        });
      } catch (error) {
        console.error("Failed to load session events", error);
        setEventsBySession((prev) => ({
          ...prev,
          [sessionId]: {
            ...(prev[sessionId] ?? emptyEventsState),
            loading: false,
            error: true,
          },
        }));
      }
    },
    [namePrefix, userId],
  );

  const toggleSession = (sessionId: string) => {
    if (openSessionId === sessionId) {
      setOpenSessionId(null);
      return;
    }
    setOpenSessionId(sessionId);
    if (!eventsBySession[sessionId]) loadEvents(sessionId);
  };

  if (sessions.length === 0) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-6 text-center text-sm text-gray-500">
        Không có session nào trong khoảng thời gian này.
      </div>
    );
  }

  let lastDayLabel = "";

  return (
    <div className="space-y-2">
      {truncated ? (
        <p className="text-xs text-amber-700">
          Đang hiển thị số session tối đa cho khoảng này — thu hẹp khoảng thời
          gian để xem đầy đủ.
        </p>
      ) : null}

      {sessions.map((session) => {
        const dayLabel = formatDayLabel(session.startAt);
        const showDayHeader = dayLabel !== lastDayLabel;
        lastDayLabel = dayLabel;
        const state = eventsBySession[session.sessionId] ?? emptyEventsState;
        const isOpen = openSessionId === session.sessionId;

        return (
          <div key={session.sessionId}>
            {showDayHeader ? (
              <div className="px-1 pt-2 pb-1 text-xs font-semibold uppercase tracking-wide text-gray-400">
                {dayLabel}
              </div>
            ) : null}

            <div className="rounded-lg border border-gray-200 bg-white">
              <button
                type="button"
                onClick={() => toggleSession(session.sessionId)}
                className="flex w-full items-center gap-2 px-3 py-2 text-left hover:bg-gray-50"
              >
                {isOpen ? (
                  <ChevronDownIcon className="h-4 w-4 text-gray-400" />
                ) : (
                  <ChevronRightIcon className="h-4 w-4 text-gray-400" />
                )}
                <span className="font-mono text-xs text-gray-700">
                  {formatClock(session.startAt)} – {formatClock(session.endAt)}
                </span>
                <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[11px] font-semibold text-slate-600">
                  {formatDuration(session.durationMs)}
                </span>
                <span className="text-xs text-gray-500">
                  {session.eventCount} event
                </span>
                <span
                  className="flex-1 truncate text-xs text-gray-500"
                  title={session.firstScreen}
                >
                  {session.firstScreen ? `vào: ${session.firstScreen}` : ""}
                  {session.lastScreen && session.lastScreen !== session.firstScreen
                    ? ` → ${session.lastScreen}`
                    : ""}
                </span>
                {session.appEnv ? (
                  <span className="rounded border border-gray-200 px-1 text-[10px] uppercase text-gray-500">
                    {session.appEnv}
                  </span>
                ) : null}
                {session.platform ? (
                  <span className="text-[11px] text-gray-400">
                    {session.platform}
                    {session.appVersion ? ` v${session.appVersion}` : ""}
                  </span>
                ) : null}
              </button>

              {isOpen ? (
                <div className="border-t border-gray-100">
                  {state.loading && state.items.length === 0 ? (
                    <div className="px-3 py-4 text-sm text-gray-500">
                      Đang tải event...
                    </div>
                  ) : state.error && state.items.length === 0 ? (
                    <div className="flex items-center gap-2 px-3 py-4 text-sm text-rose-600">
                      Không tải được event.
                      <button
                        type="button"
                        onClick={() => loadEvents(session.sessionId)}
                        className="text-blue-600 hover:text-blue-800"
                      >
                        Thử lại
                      </button>
                    </div>
                  ) : state.items.length === 0 ? (
                    <div className="px-3 py-4 text-sm text-gray-500">
                      Không có event khớp bộ lọc trong session này.
                    </div>
                  ) : (
                    <>
                      {state.items.map((event, index) => (
                        <EventRow
                          key={`${event.name}-${event.clientTs}-${index}`}
                          event={event}
                        />
                      ))}
                      {state.nextCursor ? (
                        <div className="px-3 py-2">
                          <button
                            type="button"
                            onClick={() =>
                              loadEvents(
                                session.sessionId,
                                state.nextCursor ?? undefined,
                              )
                            }
                            disabled={state.loading}
                            className="rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-700 hover:bg-gray-50 disabled:opacity-70"
                          >
                            {state.loading ? "Đang tải..." : "Tải thêm event"}
                          </button>
                        </div>
                      ) : null}
                    </>
                  )}
                </div>
              ) : null}
            </div>
          </div>
        );
      })}
    </div>
  );
}
