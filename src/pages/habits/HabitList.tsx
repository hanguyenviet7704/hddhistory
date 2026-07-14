// src/pages/habits/HabitList.tsx
import React, { useEffect, useMemo, useState } from "react";
import {
  Button,
  Checkbox,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from "@mui/material";
import {
  ChevronDownIcon,
  ChevronRightIcon,
  PencilIcon,
  PlusIcon,
  TrashIcon,
} from "lucide-react";
import { habitService } from "../../services/habitService";
import { skillsetService } from "../../services/skillsetService";
import { courseService } from "../../services/courseService";
import { keypointService } from "../../services/keypointService";
import { lessonService } from "../../services/lessonService";
import { IHabit, HabitPayload } from "../../types/interface/habit.interface";
import { HabitStatus } from "../../types/enum/habit.enum";
import { ISkillset } from "../../types/interface/skillset.interface";
import { ICourse } from "../../types/interface/course.interface";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { getTranslationValue } from "../../utils/translation";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";
import HabitModal from "../../components/habits/HabitModal";
import HabitConfirm from "../../components/habits/HabitConfirm";
import ExportImportButtons from "../../components/common/ExportImportButtons";
import {
  downloadHabitXlsx,
  parseHabitXlsx,
} from "../../utils/habitContentXlsx";

const statusPillClasses: Record<HabitStatus, string> = {
  [HabitStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
  [HabitStatus.PUBLISHED]: "bg-green-100 text-green-700",
};

const statusLabels: Record<HabitStatus, string> = {
  [HabitStatus.DRAFT]: "Draft",
  [HabitStatus.PUBLISHED]: "Published",
};

const HabitList: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [habits, setHabits] = useState<IHabit[]>([]);
  const [skillsets, setSkillsets] = useState<ISkillset[]>([]);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<HabitStatus | "">("");
  const [skillsetFilter, setSkillsetFilter] = useState("");
  // Course filter for habits: habits store keypointIds, not courseId, so a
  // course is resolved to the set of its keypoint ids (via its lessons) and
  // habits are kept when any of their keypoints is in that set. null = no
  // course filter; empty set = course selected but it has no keypoints.
  const [courseFilter, setCourseFilter] = useState("");
  const [courseKeypointIds, setCourseKeypointIds] = useState<Set<string> | null>(
    null
  );

  const [modalOpen, setModalOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IHabit | null>(null);

  // Bulk selection (select-all-visible + bulk delete / publish / unpublish).
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [confirmBulkDelete, setConfirmBulkDelete] = useState(false);
  const [bulkBusy, setBulkBusy] = useState(false);

  // Collapsed-by-default accordion groups; a keypoint id is in the set when the
  // user has expanded it. An active search force-expands everything so matches
  // are never hidden behind a collapsed header.
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());
  const toggleGroup = (id: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const skillsetNameById = useMemo(() => {
    const map = new Map<string, string>();
    skillsets.forEach((skillset) => {
      map.set(skillset._id, getTranslationValue(skillset.title, lang));
    });
    return map;
  }, [skillsets, lang]);

  // keypointId -> title, so the list can group habits under the keypoint that
  // suggests them (a habit carries only keypointIds, not the keypoint titles).
  const keypointNameById = useMemo(() => {
    const map = new Map<string, string>();
    keypoints.forEach((keypoint) => {
      map.set(keypoint._id, getTranslationValue(keypoint.title, lang));
    });
    return map;
  }, [keypoints, lang]);

  const fetchSkillsets = async () => {
    try {
      const response = await skillsetService.getList({
        isAll: true,
        take: 1000,
      });
      setSkillsets(response.data?.items ?? []);
    } catch (err) {
      console.error("Failed to load skillsets", err);
    }
  };

  // Fetched once and handed to HabitModal so it can offer a course-scoped
  // lesson/keypoint picker for `keypointIds` without re-fetching on every open.
  const fetchCourses = async () => {
    try {
      const response = await courseService.getList({
        isAll: true,
        take: 1000,
      });
      setCourses(response.data?.items ?? []);
    } catch (err) {
      console.error("Failed to load courses", err);
    }
  };

  // Fetched once to resolve keypoint titles for the grouped list view.
  // KeypointListQuery has no `isAll`, so pull a large page to cover all.
  const fetchKeypoints = async () => {
    try {
      const response = await keypointService.getList({
        page: 1,
        take: 10000,
      });
      setKeypoints(response.data?.items ?? []);
    } catch (err) {
      console.error("Failed to load keypoints", err);
    }
  };

  // The API ignores `status` whenever `isAll` is set (isAll wins), so the
  // admin list always fetches every status and filters by status client
  // side. `skillsetId` is not affected by that rule and is still sent to
  // narrow the query server side.
  const fetchHabits = async (skillsetIdFilter = skillsetFilter) => {
    setLoading(true);
    setError(null);
    try {
      const response = await habitService.getList({
        isAll: true,
        ...(skillsetIdFilter && { skillsetId: skillsetIdFilter }),
      });
      setHabits(response.data ?? []);
    } catch (err: any) {
      const message =
        err?.response?.data?.message ?? "Failed to load habits";
      setError(message);
      showError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSkillsets();
    fetchCourses();
    fetchKeypoints();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    fetchHabits(skillsetFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [skillsetFilter]);

  // Resolve the selected course to the set of keypoint ids it owns (via its
  // lessons), so habits can be filtered by course. Cleared when no course is
  // picked. Guarded against a stale response when the filter changes fast.
  useEffect(() => {
    if (!courseFilter) {
      setCourseKeypointIds(null);
      return;
    }
    let active = true;
    (async () => {
      try {
        const res = await lessonService.getList({
          courseId: courseFilter,
          take: 1000,
        });
        const lessons = (res.data?.items ?? []) as { keypoints?: IKeypoint[] }[];
        const ids = new Set<string>();
        for (const lesson of lessons) {
          for (const kp of lesson.keypoints ?? []) {
            if (kp?._id) ids.add(kp._id);
          }
        }
        if (active) setCourseKeypointIds(ids);
      } catch (err) {
        console.error("Failed to resolve course keypoints", err);
        if (active) setCourseKeypointIds(new Set());
      }
    })();
    return () => {
      active = false;
    };
  }, [courseFilter]);

  const filteredHabits = useMemo(() => {
    return habits.filter((habit) => {
      if (statusFilter && habit.status !== statusFilter) return false;
      // Course filter: keep habits attached to any keypoint of the course.
      if (courseKeypointIds) {
        const inCourse = (habit.keypointIds ?? []).some((id) =>
          courseKeypointIds.has(id)
        );
        if (!inCourse) return false;
      }
      if (search.trim()) {
        const term = search.trim().toLowerCase();
        // Search across every locale so a habit is findable regardless of the
        // language the admin is currently viewing.
        const matches = Object.values(habit.title ?? {}).some((value) =>
          (value ?? "").toLowerCase().includes(term)
        );
        if (!matches) return false;
      }
      return true;
    });
  }, [habits, search, statusFilter, courseKeypointIds]);

  const hasActiveFilters =
    !!search.trim() || !!statusFilter || !!skillsetFilter || !!courseFilter;

  // Group the filtered habits by keypoint so a keypoint's habits sit together
  // instead of scattered. A habit attached to several keypoints appears under
  // each; a habit with none falls into a trailing "No keypoint" group. Groups
  // are ordered by keypoint title, with the "No keypoint" group last.
  const NO_KEYPOINT = "__none__";
  const habitGroups = useMemo(() => {
    const groups = new Map<string, IHabit[]>();
    for (const habit of filteredHabits) {
      const kpIds = habit.keypointIds?.length ? habit.keypointIds : [NO_KEYPOINT];
      for (const kpId of kpIds) {
        const arr = groups.get(kpId) ?? [];
        arr.push(habit);
        groups.set(kpId, arr);
      }
    }
    return Array.from(groups.entries())
      .map(([keypointId, items]) => ({
        keypointId,
        label:
          keypointId === NO_KEYPOINT
            ? "No keypoint"
            : keypointNameById.get(keypointId) || "Unknown keypoint",
        items,
      }))
      .sort((a, b) => {
        if (a.keypointId === NO_KEYPOINT) return 1;
        if (b.keypointId === NO_KEYPOINT) return -1;
        return a.label.localeCompare(b.label);
      });
  }, [filteredHabits, keypointNameById]);

  const filteredHabitIds = useMemo(
    () => filteredHabits.map((habit) => habit._id),
    [filteredHabits]
  );
  const selectedCount = selectedIds.length;
  const allVisibleSelected =
    filteredHabitIds.length > 0 &&
    filteredHabitIds.every((id) => selectedIds.includes(id));
  const someVisibleSelected = selectedCount > 0 && !allVisibleSelected;

  // Clear selection whenever the visible set changes via search/filters, so a
  // bulk action can never act on a row that is no longer shown.
  useEffect(() => {
    setSelectedIds([]);
  }, [search, statusFilter, skillsetFilter, courseKeypointIds]);

  const toggleOne = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const toggleAllVisible = () => {
    setSelectedIds((prev) =>
      allVisibleSelected
        ? prev.filter((id) => !filteredHabitIds.includes(id))
        : Array.from(new Set([...prev, ...filteredHabitIds]))
    );
  };

  // Run a per-id action over the current selection. Uses allSettled so one
  // failing row doesn't abort the batch; reports succeeded/total on partial
  // failure. Clears the selection and refetches when done.
  const runBulk = async (
    action: (id: string) => Promise<unknown>,
    verb: string
  ) => {
    const ids = [...selectedIds];
    if (ids.length === 0) return;
    setBulkBusy(true);
    try {
      const results = await Promise.allSettled(ids.map((id) => action(id)));
      const ok = results.filter((r) => r.status === "fulfilled").length;
      const failed = ids.length - ok;
      if (failed === 0) {
        showSuccess(`${verb} ${ok} habit${ok === 1 ? "" : "s"} successfully`);
      } else {
        showError(`${verb} ${ok}/${ids.length} habits — ${failed} failed`);
      }
      setSelectedIds([]);
      await fetchHabits();
    } finally {
      setBulkBusy(false);
    }
  };

  const handleBulkDelete = async () => {
    setConfirmBulkDelete(false);
    await runBulk((id) => habitService.remove(id), "Deleted");
  };

  const handleBulkStatus = async (status: HabitStatus) => {
    await runBulk(
      (id) => habitService.update(id, { status }),
      status === HabitStatus.PUBLISHED ? "Published" : "Unpublished"
    );
  };

  const resetFilters = () => {
    setSearch("");
    setStatusFilter("");
    setSkillsetFilter("");
    setCourseFilter("");
  };

  const openCreateModal = () => {
    setSelected(null);
    setModalOpen(true);
  };

  const openEditModal = (habit: IHabit) => {
    setSelected(habit);
    setModalOpen(true);
  };

  const openDeleteConfirm = (habit: IHabit) => {
    setSelected(habit);
    setConfirmOpen(true);
  };

  const handleSubmit = async (payload: HabitPayload, id?: string) => {
    if (id) {
      await habitService.update(id, payload);
      showSuccess("Habit updated successfully");
    } else {
      await habitService.create(payload);
      showSuccess("Habit created successfully");
    }
    setModalOpen(false);
    await fetchHabits();
  };

  const handleDelete = async () => {
    if (!selected) return;
    try {
      await habitService.remove(selected._id);
      showSuccess("Habit deleted successfully");
      setConfirmOpen(false);
      setSelected(null);
      await fetchHabits();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to delete habit");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">🔁 Habits</h1>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search habit title..."
                className="w-full md:w-72 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
              />
              <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                </svg>
              </div>
            </div>
            <select
              value={skillsetFilter}
              onChange={(e) => setSkillsetFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
            >
              <option value="">All skillsets</option>
              {skillsets.map((skillset) => (
                <option key={skillset._id} value={skillset._id}>
                  {getTranslationValue(skillset.title, lang)}
                </option>
              ))}
            </select>
            <select
              value={courseFilter}
              onChange={(e) => setCourseFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
            >
              <option value="">All courses</option>
              {courses.map((course) => (
                <option key={course._id} value={course._id}>
                  {getTranslationValue(course.title, lang)}
                </option>
              ))}
            </select>
            <select
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as HabitStatus | "")
              }
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
            >
              <option value="">All statuses</option>
              <option value={HabitStatus.DRAFT}>Draft</option>
              <option value={HabitStatus.PUBLISHED}>Published</option>
            </select>
            <ExportImportButtons
              label="habits"
              onExport={async () => {
                const rows = await habitService.exportData();
                downloadHabitXlsx(rows);
              }}
              onParse={parseHabitXlsx}
              onImport={(rows) => habitService.importData(rows)}
              onImported={() => fetchHabits()}
            />
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Create habit</span>
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto">
        {selectedCount > 0 && (
          <div className="mb-4 flex flex-col gap-3 rounded-lg border border-gray-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
            <span className="text-sm font-medium text-gray-700">
              {selectedCount} selected
            </span>
            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={() => handleBulkStatus(HabitStatus.PUBLISHED)}
                disabled={bulkBusy}
                className="inline-flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                Publish selected
              </button>
              <button
                type="button"
                onClick={() => handleBulkStatus(HabitStatus.DRAFT)}
                disabled={bulkBusy}
                className="inline-flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
              >
                Unpublish selected
              </button>
              <button
                type="button"
                onClick={() => setConfirmBulkDelete(true)}
                disabled={bulkBusy}
                className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <TrashIcon className="h-4 w-4" />
                Delete selected
              </button>
            </div>
          </div>
        )}
        {loading ? (
          <TableContainer
            component={Paper}
            elevation={3}
            sx={{ borderRadius: 2 }}
            className="overflow-x-auto"
          >
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Title</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Skillset</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Order</TableCell>
                  <TableCell sx={{ fontWeight: 600 }} align="right">
                    Actions
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {Array.from({ length: 5 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 5 }).map((__, j) => (
                      <TableCell key={j}>
                        <Skeleton variant="text" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        ) : error ? (
          <div className="bg-white rounded-xl shadow-md p-8 text-center">
            <p className="text-red-600 mb-4">{error}</p>
            <button
              onClick={() => fetchHabits()}
              className="inline-flex items-center gap-2 border border-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition"
            >
              Retry
            </button>
          </div>
        ) : habits.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md p-8 text-center">
            <p className="text-gray-600 mb-4">
              No habits yet — create the first one to power the mobile app's
              Habit feature.
            </p>
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg mx-auto"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Create the first habit</span>
            </button>
          </div>
        ) : filteredHabits.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md p-8 text-center">
            <p className="text-gray-600 mb-4">
              No habits match your filters.
            </p>
            <button
              onClick={resetFilters}
              disabled={!hasActiveFilters}
              className="inline-flex items-center gap-2 border border-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent"
            >
              Reset filters
            </button>
          </div>
        ) : (
          <TableContainer
            component={Paper}
            elevation={3}
            sx={{ borderRadius: 2 }}
            className="overflow-x-auto"
          >
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={allVisibleSelected}
                      indeterminate={someVisibleSelected}
                      onChange={toggleAllVisible}
                      inputProps={{ "aria-label": "Select all visible habits" }}
                    />
                  </TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Title</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Skillset</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Order</TableCell>
                  <TableCell sx={{ fontWeight: 600 }} align="right">
                    Actions
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {habitGroups.map((group) => {
                  const open =
                    !!search.trim() || expandedGroups.has(group.keypointId);
                  return (
                  <React.Fragment key={group.keypointId}>
                    <TableRow
                      hover
                      onClick={() => toggleGroup(group.keypointId)}
                      sx={{ cursor: "pointer" }}
                    >
                      <TableCell
                        colSpan={6}
                        sx={{
                          backgroundColor: "grey.100",
                          fontWeight: 700,
                          color: "text.secondary",
                        }}
                      >
                        <span
                          style={{
                            display: "inline-flex",
                            alignItems: "center",
                            gap: 8,
                          }}
                        >
                          {open ? (
                            <ChevronDownIcon size={18} />
                          ) : (
                            <ChevronRightIcon size={18} />
                          )}
                          {group.label}{" "}
                          <span style={{ fontWeight: 500, opacity: 0.7 }}>
                            ({group.items.length})
                          </span>
                        </span>
                      </TableCell>
                    </TableRow>
                    {open &&
                      group.items.map((habit) => (
                      <TableRow
                        key={`${group.keypointId}-${habit._id}`}
                        hover
                        selected={selectedIds.includes(habit._id)}
                      >
                        <TableCell padding="checkbox">
                          <Checkbox
                            checked={selectedIds.includes(habit._id)}
                            onChange={() => toggleOne(habit._id)}
                            inputProps={{ "aria-label": "Select habit" }}
                          />
                        </TableCell>
                        <TableCell>
                          {getTranslationValue(habit.title, lang) || "—"}
                        </TableCell>
                        <TableCell>
                          {skillsetNameById.get(habit.skillsetId) ||
                            "Unknown skillset"}
                        </TableCell>
                        <TableCell>
                          <span
                            className={`px-2.5 py-0.5 rounded-full text-xs font-medium inline-block ${
                              statusPillClasses[habit.status]
                            }`}
                          >
                            {statusLabels[habit.status]}
                          </span>
                        </TableCell>
                        <TableCell>{habit.order}</TableCell>
                        <TableCell align="right">
                          <button
                            aria-label="Edit habit"
                            onClick={() => openEditModal(habit)}
                            className="p-2 rounded-full hover:bg-gray-100 transition-colors"
                          >
                            <PencilIcon className="h-5 w-5 text-blue-600" />
                          </button>
                          <button
                            aria-label="Delete habit"
                            onClick={() => openDeleteConfirm(habit)}
                            className="p-2 rounded-full hover:bg-gray-100 transition-colors"
                          >
                            <TrashIcon className="h-5 w-5 text-red-600" />
                          </button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </React.Fragment>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </div>

      <HabitModal
        isOpen={modalOpen}
        initial={selected}
        skillsets={skillsets}
        courses={courses}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
      />

      <HabitConfirm
        isOpen={confirmOpen}
        habit={selected}
        onClose={() => {
          setConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={handleDelete}
      />

      <Dialog
        open={confirmBulkDelete}
        onClose={() => !bulkBusy && setConfirmBulkDelete(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Delete {selectedCount} habits</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete {selectedCount} selected habit
            {selectedCount === 1 ? "" : "s"}? This action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={() => setConfirmBulkDelete(false)} disabled={bulkBusy}>
            Cancel
          </Button>
          <Button
            onClick={handleBulkDelete}
            color="error"
            variant="contained"
            disabled={bulkBusy}
            startIcon={
              bulkBusy ? (
                <CircularProgress size={16} color="inherit" />
              ) : undefined
            }
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default HabitList;
