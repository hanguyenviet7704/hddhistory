import React, { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import {
  ArrowPathIcon,
  ChevronRightIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";
import { Link } from "react-router-dom";

import { userHabitService } from "../../services/userHabitService";
import { UserHabitState } from "../../types/enum/habit.enum";
import { IAdminUserHabitSummary } from "../../types/interface/userHabit.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { formatDateOnly } from "./habitCheckinLabels";
import HabitCheckinStats from "./HabitCheckinStats";

const DEFAULT_PAGE_SIZE = 10;

type CheckinTab = "stats" | "users";

const TABS: { value: CheckinTab; label: string }[] = [
  { value: "stats", label: "Thống kê" },
  { value: "users", label: "Theo người dùng" },
];

const STATE_OPTIONS: { value: UserHabitState | ""; label: string }[] = [
  { value: "", label: "All states" },
  { value: UserHabitState.ACTIVE, label: "Active" },
  { value: UserHabitState.DRAFT, label: "Draft" },
  { value: UserHabitState.ARCHIVED, label: "Archived" },
];

/**
 * Who is actually using habits, and how. One row per user who has adopted at
 * least one habit; drill into a row for their full check-in log including the
 * journal text they wrote.
 *
 * Counts come from `habit_checkins` rather than the denormalised counters on
 * `user_habits`, so a drift between the two shows up here as the truth.
 */
export default function HabitCheckinList() {
  const { showError } = useNotification();

  // Lands on the aggregate view: the per-user table is still one click away and
  // stays mounted (hidden) so switching back keeps its page and search.
  const [tab, setTab] = useState<CheckinTab>("stats");
  const [items, setItems] = useState<IAdminUserHabitSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [forbidden, setForbidden] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [stateFilter, setStateFilter] = useState<UserHabitState | "">("");

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1);
    }, 500);
    return () => clearTimeout(handler);
  }, [search]);

  const fetchSummaries = useCallback(
    async (
      pageNumber: number,
      searchQuery: string,
      state: UserHabitState | "",
    ) => {
      setLoading(true);
      try {
        const data = await userHabitService.getUserSummaries({
          page: pageNumber,
          take: DEFAULT_PAGE_SIZE,
          search: searchQuery.trim() || undefined,
          state: state || undefined,
        });
        setItems(data?.items ?? []);
        setTotalPages(data?.totalPages || 1);
        setForbidden(false);
      } catch (error: any) {
        // A 403 here means the signed-in account is not role ADMIN. That is a
        // different thing from "no habit data" and must not render as an empty
        // table, or it looks like the feature is broken.
        if (error?.response?.status === 403) {
          setForbidden(true);
          setItems([]);
        } else {
          console.error("Failed to fetch habit check-in summaries", error);
          showError("Failed to load habit check-ins");
        }
      } finally {
        setLoading(false);
      }
    },
    [showError],
  );

  useEffect(() => {
    fetchSummaries(page, debouncedSearch, stateFilter);
  }, [fetchSummaries, page, debouncedSearch, stateFilter]);

  return (
    <div className="p-6">
      <div className="mb-6 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Habit check-ins</h1>
          <p className="mt-1 text-sm text-gray-500">
            How users check in on their habits — quick taps, journal entries and
            quiz practices.
          </p>
        </div>
        {/* Only the per-user table is fetched imperatively; the stats tab
            refetches whenever its own date filter changes. */}
        {tab === "users" ? (
          <button
            onClick={() => fetchSummaries(page, debouncedSearch, stateFilter)}
            disabled={loading}
            className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            <ArrowPathIcon
              className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
            />
            Refresh
          </button>
        ) : null}
      </div>

      <div className="mb-6 flex gap-2">
        {TABS.map((item) => (
          <button
            key={item.value}
            type="button"
            onClick={() => setTab(item.value)}
            className={`rounded-lg px-4 py-2 text-sm font-semibold transition ${
              tab === item.value
                ? "bg-indigo-600 text-white"
                : "bg-white text-slate-600 ring-1 ring-slate-200 hover:bg-slate-50"
            }`}
          >
            {item.label}
          </button>
        ))}
      </div>

      {tab === "stats" ? <HabitCheckinStats /> : null}

      <div
        className={`overflow-hidden rounded-xl border border-gray-200 bg-white ${
          tab === "users" ? "" : "hidden"
        }`}
      >
        <div className="flex flex-wrap items-center gap-3 border-b border-gray-200 bg-gray-50 p-4">
          <div className="relative min-w-[260px] flex-1">
            <MagnifyingGlassIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by email or name…"
              className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm outline-none focus:border-indigo-500"
            />
          </div>
          <select
            value={stateFilter}
            onChange={(e) => {
              setStateFilter(e.target.value as UserHabitState | "");
              setPage(1);
            }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
          >
            {STATE_OPTIONS.map((option) => (
              <option key={option.value || "all"} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        {forbidden ? (
          <div className="p-10 text-center">
            <p className="font-semibold text-gray-900">Admin role required</p>
            <p className="mt-1 text-sm text-gray-500">
              This view reads every user's habit data, so the API restricts it to
              accounts with role <code>ADMIN</code>. Your account is signed in
              but not an admin.
            </p>
          </div>
        ) : loading && items.length === 0 ? (
          <div className="p-10 text-center text-sm text-gray-500">Loading…</div>
        ) : items.length === 0 ? (
          <div className="p-10 text-center text-sm text-gray-500">
            {debouncedSearch || stateFilter
              ? "No users match this filter."
              : "Nobody has adopted a habit yet."}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-white">
                <tr className="text-left text-xs uppercase tracking-wide text-gray-500">
                  <th className="px-4 py-3 font-semibold">User</th>
                  <th className="px-4 py-3 font-semibold">Habits</th>
                  <th className="px-4 py-3 font-semibold">Check-ins</th>
                  <th className="px-4 py-3 font-semibold">Journal</th>
                  <th className="px-4 py-3 font-semibold">Quiz</th>
                  <th className="px-4 py-3 font-semibold">Best streak</th>
                  <th className="px-4 py-3 font-semibold">Last check-in</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {items.map((row) => (
                  <tr key={row.userId} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="font-semibold text-gray-900">
                        {row.user?.name || "(no name)"}
                      </div>
                      <div className="text-xs text-gray-500">
                        {/* No users row means the account was deleted while its
                            habits stayed behind — worth seeing, not hiding. */}
                        {row.user?.email ?? `deleted user · ${row.userId}`}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {row.habitCount}
                      <span className="ml-1 text-xs text-gray-400">
                        ({row.activeCount} active)
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {row.doneCount}
                      <span className="ml-1 text-xs text-gray-400">
                        / {row.checkinRows} rows
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {row.journalCount > 0 ? (
                        <span className="rounded-full bg-indigo-100 px-2 py-0.5 text-xs font-semibold text-indigo-700">
                          {row.journalCount}
                        </span>
                      ) : (
                        <span className="text-gray-300">0</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {row.quizCount > 0 ? (
                        <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700">
                          {row.quizCount}
                        </span>
                      ) : (
                        <span className="text-gray-300">0</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {row.bestStreak}
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {formatDateOnly(row.lastCheckInDate)}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Link
                        to={`/habit-checkins/user/${row.userId}`}
                        className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                      >
                        Detail
                        <ChevronRightIcon className="h-4 w-4" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {items.length > 0 && totalPages > 1 && (
          <div className="flex justify-end border-t border-gray-200 bg-gray-50 p-4">
            <Pagination
              count={totalPages}
              page={page}
              onChange={(_, value) => setPage(value)}
              color="primary"
              shape="rounded"
            />
          </div>
        )}
      </div>
    </div>
  );
}
