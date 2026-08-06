import React, { useCallback, useEffect, useState } from "react";
import { ArrowLeftIcon, ArrowPathIcon } from "@heroicons/react/24/outline";
import { Link, useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import { RootState } from "../../store";
import { userHabitService } from "../../services/userHabitService";
import { UserHabitState } from "../../types/enum/habit.enum";
import { IAdminUserHabitDetail } from "../../types/interface/userHabit.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  MethodPill,
  formatDateOnly,
  renderMood,
} from "./habitCheckinLabels";

const STATE_PILL_CLASSES: Record<UserHabitState, string> = {
  [UserHabitState.ACTIVE]: "bg-green-100 text-green-700",
  [UserHabitState.DRAFT]: "bg-yellow-100 text-yellow-700",
  [UserHabitState.ARCHIVED]: "bg-gray-100 text-gray-600",
};

const Stat: React.FC<{ label: string; value: React.ReactNode }> = ({
  label,
  value,
}) => (
  <div className="rounded-lg border border-gray-200 bg-white px-4 py-3">
    <div className="text-xs uppercase tracking-wide text-gray-500">{label}</div>
    <div className="mt-1 text-lg font-bold text-gray-900">{value}</div>
  </div>
);

/**
 * One user's habits and their complete check-in log, including the full journal
 * text. That text is personal diary content — this page exists so the team can
 * read what users actually write, which is the whole point of the journal
 * check-in, but treat it accordingly.
 */
export default function HabitCheckinDetail() {
  const { userId } = useParams<{ userId: string }>();
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError } = useNotification();

  const [detail, setDetail] = useState<IAdminUserHabitDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [forbidden, setForbidden] = useState(false);
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const fetchDetail = useCallback(async () => {
    if (!userId) return;
    setLoading(true);
    try {
      const data = await userHabitService.getUserDetail(userId, {
        from: from || undefined,
        to: to || undefined,
      });
      setDetail(data);
      setForbidden(false);
    } catch (error: any) {
      if (error?.response?.status === 403) {
        setForbidden(true);
        setDetail(null);
      } else {
        console.error("Failed to fetch habit check-in detail", error);
        showError("Failed to load this user's habit check-ins");
      }
    } finally {
      setLoading(false);
    }
  }, [userId, from, to, showError]);

  useEffect(() => {
    fetchDetail();
  }, [fetchDetail]);

  const totals = detail?.totals;

  return (
    <div className="p-6">
      <Link
        to="/habit-checkins"
        className="mb-4 inline-flex items-center gap-1 text-sm font-semibold text-indigo-600 hover:text-indigo-800"
      >
        <ArrowLeftIcon className="h-4 w-4" />
        Back to habit check-ins
      </Link>

      {forbidden ? (
        <div className="rounded-xl border border-gray-200 bg-white p-10 text-center">
          <p className="font-semibold text-gray-900">Admin role required</p>
          <p className="mt-1 text-sm text-gray-500">
            This view reads another user's habit data, so the API restricts it to
            accounts with role <code>ADMIN</code>.
          </p>
        </div>
      ) : (
        <>
          <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {detail?.user?.name || "(no name)"}
              </h1>
              <p className="mt-1 text-sm text-gray-500">
                {detail?.user?.email ?? `deleted user · ${userId}`}
                {detail?.user?.role ? ` · ${detail.user.role}` : ""}
                {detail?.user?.status ? ` · ${detail.user.status}` : ""}
              </p>
            </div>
            <div className="flex flex-wrap items-end gap-3">
              <label className="text-xs font-semibold text-gray-600">
                From
                <input
                  type="date"
                  value={from}
                  onChange={(e) => setFrom(e.target.value)}
                  className="mt-1 block rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
                />
              </label>
              <label className="text-xs font-semibold text-gray-600">
                To
                <input
                  type="date"
                  value={to}
                  onChange={(e) => setTo(e.target.value)}
                  className="mt-1 block rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
                />
              </label>
              <button
                onClick={fetchDetail}
                disabled={loading}
                className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                <ArrowPathIcon
                  className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
                />
                Refresh
              </button>
            </div>
          </div>

          {totals && (
            <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
              <Stat label="Habits" value={totals.habitCount} />
              <Stat label="Active" value={totals.activeCount} />
              <Stat label="Check-in rows" value={totals.checkinRows} />
              <Stat label="Done" value={totals.doneCount} />
              <Stat label="Journal" value={totals.journalCount} />
              <Stat label="Quiz" value={totals.quizCount} />
            </div>
          )}

          {loading && !detail ? (
            <div className="rounded-xl border border-gray-200 bg-white p-10 text-center text-sm text-gray-500">
              Loading…
            </div>
          ) : !detail || detail.habits.length === 0 ? (
            <div className="rounded-xl border border-gray-200 bg-white p-10 text-center text-sm text-gray-500">
              This user has no adopted habits
              {from || to ? " in the selected date range" : ""}.
            </div>
          ) : (
            <div className="space-y-5">
              {detail.habits.map((habit) => (
                <div
                  key={habit.id}
                  className="overflow-hidden rounded-xl border border-gray-200 bg-white"
                >
                  <div className="flex flex-wrap items-start justify-between gap-3 border-b border-gray-200 bg-gray-50 p-4">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-semibold text-gray-900">
                          {habit.title ? (
                            getTranslationValue(habit.title, lang)
                          ) : (
                            // The library entry was deleted. The app hides these
                            // orphans; the admin shows them, because an orphan is
                            // exactly what this page should make visible.
                            <span className="italic text-rose-600">
                              Orphaned habit (library entry deleted)
                            </span>
                          )}
                        </span>
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-semibold ${STATE_PILL_CLASSES[habit.state]}`}
                        >
                          {habit.state}
                        </span>
                      </div>
                      <div className="mt-1 text-xs text-gray-500">
                        Started {formatDateOnly(habit.startedAt)} · pack{" "}
                        {habit.packLength}d
                        {habit.reminderTime
                          ? ` · reminder ${habit.reminderTime}`
                          : ""}
                      </div>
                      {habit.reanchorReason && (
                        <div className="mt-1 text-xs text-gray-500">
                          Why: {getTranslationValue(habit.reanchorReason, lang)}
                        </div>
                      )}
                    </div>
                    <div className="flex gap-4 text-xs text-gray-600">
                      <div>
                        <div className="text-gray-400">Streak</div>
                        <div className="font-bold text-gray-900">
                          {habit.currentStreak}
                        </div>
                      </div>
                      <div>
                        <div className="text-gray-400">Best</div>
                        <div className="font-bold text-gray-900">
                          {habit.bestStreak}
                        </div>
                      </div>
                      <div>
                        <div className="text-gray-400">Total</div>
                        <div className="font-bold text-gray-900">
                          {habit.totalCheckIns}
                        </div>
                      </div>
                    </div>
                  </div>

                  {habit.checkins.length === 0 ? (
                    <div className="p-6 text-center text-sm text-gray-500">
                      No check-ins
                      {from || to ? " in the selected date range" : " yet"}.
                    </div>
                  ) : (
                    <div className="overflow-x-auto">
                      <table className="min-w-full divide-y divide-gray-200 text-sm">
                        <thead>
                          <tr className="text-left text-xs uppercase tracking-wide text-gray-500">
                            <th className="px-4 py-2 font-semibold">Date</th>
                            <th className="px-4 py-2 font-semibold">Done</th>
                            <th className="px-4 py-2 font-semibold">Method</th>
                            <th className="px-4 py-2 font-semibold">Mood</th>
                            <th className="px-4 py-2 font-semibold">Score</th>
                            <th className="px-4 py-2 font-semibold">
                              Journal entry
                            </th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                          {habit.checkins.map((checkin) => (
                            <tr
                              key={`${habit.id}-${checkin.date}`}
                              className="align-top hover:bg-gray-50"
                            >
                              <td className="whitespace-nowrap px-4 py-2 text-gray-700">
                                {checkin.date}
                              </td>
                              <td className="px-4 py-2">
                                {checkin.done ? (
                                  <span className="text-green-600">✓</span>
                                ) : (
                                  <span className="text-gray-300">–</span>
                                )}
                              </td>
                              <td className="px-4 py-2">
                                <MethodPill method={checkin.method} />
                              </td>
                              <td className="whitespace-nowrap px-4 py-2 text-gray-700">
                                {renderMood(checkin.mood)}
                              </td>
                              <td className="px-4 py-2 text-gray-700">
                                {checkin.score ?? "-"}
                              </td>
                              <td className="px-4 py-2 text-gray-800">
                                {checkin.note?.trim() ? (
                                  // Full text, wrapped — the point of this page.
                                  <span className="whitespace-pre-wrap break-words">
                                    {checkin.note}
                                  </span>
                                ) : (
                                  <span className="text-gray-300">-</span>
                                )}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
