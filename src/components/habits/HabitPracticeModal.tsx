import React, { useCallback, useEffect, useState } from "react";
import {
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Button,
  CircularProgress,
} from "@mui/material";
import {
  ArrowDownIcon,
  ArrowUpIcon,
  MagnifyingGlassIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";

import { RootState } from "../../store";
import { habitPracticeService } from "../../services/habitPracticeService";
import { IHabit } from "../../types/interface/habit.interface";
import {
  HabitPracticeStatus,
  IHabitPractice,
  IPracticeLearningItem,
  PracticeLearningItemType,
} from "../../types/interface/habitPractice.interface";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

interface Props {
  isOpen: boolean;
  habit: IHabit | null;
  onClose: () => void;
}

const TYPE_OPTIONS = [
  { value: PracticeLearningItemType.EXERCISE, label: "Quiz (exercise)" },
  { value: PracticeLearningItemType.VIDEO, label: "Video" },
  { value: PracticeLearningItemType.ROLEPLAY, label: "Roleplay" },
];

const STATUS_PILL: Record<HabitPracticeStatus, string> = {
  [HabitPracticeStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
  [HabitPracticeStatus.PUBLISHED]: "bg-green-100 text-green-700",
};

/**
 * Point a habit at the authored content it practises.
 *
 * The habit must already exist (a practice row needs its id), which is why this
 * is opened from a row action rather than folded into the create/edit form.
 *
 * Journal is intentionally absent: it has no authored content, so it is always
 * available for every habit and needs no row here.
 */
const HabitPracticeModal: React.FC<Props> = ({ isOpen, habit, onClose }) => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [practices, setPractices] = useState<IHabitPractice[]>([]);
  const [loading, setLoading] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const [type, setType] = useState<PracticeLearningItemType>(
    PracticeLearningItemType.EXERCISE,
  );
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [candidates, setCandidates] = useState<IPracticeLearningItem[]>([]);
  const [searching, setSearching] = useState(false);

  const habitTitle = habit ? getTranslationValue(habit.title, lang) : "";

  const loadPractices = useCallback(async () => {
    if (!habit?._id) return;
    setLoading(true);
    try {
      setPractices(await habitPracticeService.list(habit._id));
    } catch (error: any) {
      if (error?.response?.status === 403) {
        showError("Admin role required to manage practices");
      } else {
        console.error("Failed to load practices", error);
        showError("Failed to load practices");
      }
    } finally {
      setLoading(false);
    }
  }, [habit?._id, showError]);

  useEffect(() => {
    if (isOpen) loadPractices();
  }, [isOpen, loadPractices]);

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedSearch(search), 400);
    return () => clearTimeout(handler);
  }, [search]);

  useEffect(() => {
    if (!isOpen) return;
    let cancelled = false;
    (async () => {
      setSearching(true);
      try {
        const { items } = await habitPracticeService.searchLearningItems({
          type,
          search: debouncedSearch,
          take: 20,
        });
        if (!cancelled) setCandidates(items);
      } catch (error) {
        console.error("Failed to search learning items", error);
        if (!cancelled) setCandidates([]);
      } finally {
        if (!cancelled) setSearching(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [isOpen, type, debouncedSearch]);

  const attachedIds = new Set(practices.map((p) => p.learningItemId));

  const attach = async (item: IPracticeLearningItem) => {
    if (!habit?._id) return;
    setBusyId(item._id);
    try {
      await habitPracticeService.create({
        habitId: habit._id,
        learningItemId: item._id,
        // Appended, so attach order is the order the app shows.
        order: practices.length,
        status: HabitPracticeStatus.DRAFT,
      });
      showSuccess("Practice attached");
      await loadPractices();
    } catch (error: any) {
      // The API rejects a theory item and a duplicate pair — surface its reason
      // rather than a generic failure, since both are editorial mistakes with a
      // clear fix.
      const message =
        error?.response?.data?.message ?? "Failed to attach practice";
      showError(Array.isArray(message) ? message.join(", ") : String(message));
    } finally {
      setBusyId(null);
    }
  };

  const patch = async (
    practice: IHabitPractice,
    payload: { order?: number; status?: HabitPracticeStatus },
  ) => {
    setBusyId(practice._id);
    try {
      await habitPracticeService.update(practice._id, payload);
      await loadPractices();
    } catch (error) {
      console.error("Failed to update practice", error);
      showError("Failed to update practice");
    } finally {
      setBusyId(null);
    }
  };

  const detach = async (practice: IHabitPractice) => {
    setBusyId(practice._id);
    try {
      await habitPracticeService.remove(practice._id);
      showSuccess("Practice removed");
      await loadPractices();
    } catch (error) {
      console.error("Failed to remove practice", error);
      showError("Failed to remove practice");
    } finally {
      setBusyId(null);
    }
  };

  // Swaps this row's `order` with its neighbour's. Two PATCHes rather than a
  // bulk reorder endpoint — the list is a handful of rows, and this keeps the
  // API surface to plain CRUD.
  const move = async (index: number, delta: number) => {
    const target = index + delta;
    if (target < 0 || target >= practices.length) return;
    const a = practices[index];
    const b = practices[target];
    setBusyId(a._id);
    try {
      await habitPracticeService.update(a._id, { order: b.order });
      await habitPracticeService.update(b._id, { order: a.order });
      await loadPractices();
    } catch (error) {
      console.error("Failed to reorder practices", error);
      showError("Failed to reorder practices");
    } finally {
      setBusyId(null);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <div className="text-lg font-bold text-gray-900">Practices</div>
        <div className="mt-0.5 text-sm font-normal text-gray-500">
          {habitTitle}
        </div>
      </DialogTitle>

      <DialogContent dividers>
        <div className="mb-6">
          <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-gray-500">
            Attached ({practices.length})
          </h3>
          <p className="mb-3 text-xs text-gray-500">
            Journal is always available for every habit and needs no row here —
            it has no authored content. Only <b>published</b> practices reach the
            app.
          </p>

          {loading ? (
            <div className="py-6 text-center">
              <CircularProgress size={22} />
            </div>
          ) : practices.length === 0 ? (
            <div className="rounded-lg border border-dashed border-gray-300 py-6 text-center text-sm text-gray-500">
              No practice attached yet. Pick content below.
            </div>
          ) : (
            <div className="space-y-2">
              {practices.map((practice, index) => (
                <div
                  key={practice._id}
                  className="flex items-center gap-3 rounded-lg border border-gray-200 p-3"
                >
                  <span className="w-6 text-center text-xs font-bold text-gray-400">
                    {index + 1}
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold text-gray-900">
                      {practice.learningItem?.title
                        ? getTranslationValue(practice.learningItem.title, lang)
                        : "(content deleted)"}
                    </div>
                    <div className="mt-0.5 text-xs text-gray-500">
                      {practice.learningItem?.type ?? "?"}
                      {practice.learningItem?.questions
                        ? ` · ${practice.learningItem.questions.length} question(s)`
                        : ""}
                      {/* No keypointId is the good case for habit-owned content:
                          the daily warm-up tagging job skips such rows. */}
                      {practice.learningItem &&
                      !practice.learningItem.keypointId ? (
                        <span className="ml-1 text-emerald-600">
                          · habit-owned
                        </span>
                      ) : null}
                    </div>
                  </div>

                  <button
                    onClick={() =>
                      patch(practice, {
                        status:
                          practice.status === HabitPracticeStatus.PUBLISHED
                            ? HabitPracticeStatus.DRAFT
                            : HabitPracticeStatus.PUBLISHED,
                      })
                    }
                    disabled={busyId === practice._id}
                    className={`rounded-full px-2 py-0.5 text-xs font-semibold disabled:opacity-50 ${STATUS_PILL[practice.status]}`}
                  >
                    {practice.status}
                  </button>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => move(index, -1)}
                      disabled={index === 0 || busyId === practice._id}
                      aria-label="Move up"
                      className="rounded p-1 hover:bg-gray-100 disabled:opacity-30"
                    >
                      <ArrowUpIcon className="h-4 w-4 text-gray-500" />
                    </button>
                    <button
                      onClick={() => move(index, 1)}
                      disabled={
                        index === practices.length - 1 ||
                        busyId === practice._id
                      }
                      aria-label="Move down"
                      className="rounded p-1 hover:bg-gray-100 disabled:opacity-30"
                    >
                      <ArrowDownIcon className="h-4 w-4 text-gray-500" />
                    </button>
                    <button
                      onClick={() => detach(practice)}
                      disabled={busyId === practice._id}
                      aria-label="Remove"
                      className="rounded p-1 hover:bg-red-50 disabled:opacity-30"
                    >
                      <TrashIcon className="h-4 w-4 text-red-600" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div>
          <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-gray-500">
            Add content
          </h3>
          <div className="mb-3 flex flex-wrap items-center gap-2">
            <select
              value={type}
              onChange={(e) =>
                setType(e.target.value as PracticeLearningItemType)
              }
              className="rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
            >
              {TYPE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
            <div className="relative min-w-[220px] flex-1">
              <MagnifyingGlassIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search content by title…"
                className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {searching ? (
            <div className="py-6 text-center">
              <CircularProgress size={22} />
            </div>
          ) : candidates.length === 0 ? (
            <div className="rounded-lg border border-dashed border-gray-300 py-6 text-center text-sm text-gray-500">
              No {type} content found
              {debouncedSearch ? ` for "${debouncedSearch}"` : ""}.
            </div>
          ) : (
            <div className="max-h-64 space-y-2 overflow-y-auto">
              {candidates.map((item) => {
                const attached = attachedIds.has(item._id);
                return (
                  <div
                    key={item._id}
                    className="flex items-center gap-3 rounded-lg border border-gray-200 p-3"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="truncate font-semibold text-gray-900">
                        {getTranslationValue(item.title, lang) || "(untitled)"}
                      </div>
                      <div className="mt-0.5 text-xs text-gray-500">
                        {item.type}
                        {item.questions
                          ? ` · ${item.questions.length} question(s)`
                          : ""}
                        {!item.keypointId ? (
                          <span className="ml-1 text-emerald-600">
                            · habit-owned
                          </span>
                        ) : (
                          <span className="ml-1 text-gray-400">
                            · on a keypoint
                          </span>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => attach(item)}
                      disabled={attached || busyId === item._id}
                      className="flex items-center gap-1 rounded-lg border border-indigo-200 bg-indigo-50 px-3 py-1.5 text-xs font-semibold text-indigo-700 hover:bg-indigo-100 disabled:opacity-40"
                    >
                      <PlusIcon className="h-4 w-4" />
                      {attached ? "Attached" : "Attach"}
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

export default HabitPracticeModal;
