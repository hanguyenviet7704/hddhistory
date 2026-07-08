// src/pages/habits/HabitList.tsx
import React, { useEffect, useMemo, useState } from "react";
import {
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from "@mui/material";
import { PencilIcon, PlusIcon, TrashIcon } from "lucide-react";
import { habitService } from "../../services/habitService";
import { skillsetService } from "../../services/skillsetService";
import { courseService } from "../../services/courseService";
import { IHabit, HabitPayload } from "../../types/interface/habit.interface";
import { HabitStatus } from "../../types/enum/habit.enum";
import { ISkillset } from "../../types/interface/skillset.interface";
import { ICourse } from "../../types/interface/course.interface";
import { getTranslationValue } from "../../utils/translation";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";
import HabitModal from "../../components/habits/HabitModal";
import HabitConfirm from "../../components/habits/HabitConfirm";

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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<HabitStatus | "">("");
  const [skillsetFilter, setSkillsetFilter] = useState("");

  const [modalOpen, setModalOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IHabit | null>(null);

  const skillsetNameById = useMemo(() => {
    const map = new Map<string, string>();
    skillsets.forEach((skillset) => {
      map.set(skillset._id, getTranslationValue(skillset.title, lang));
    });
    return map;
  }, [skillsets, lang]);

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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    fetchHabits(skillsetFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [skillsetFilter]);

  const filteredHabits = useMemo(() => {
    return habits.filter((habit) => {
      if (statusFilter && habit.status !== statusFilter) return false;
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
  }, [habits, search, statusFilter]);

  const hasActiveFilters = !!search.trim() || !!statusFilter || !!skillsetFilter;

  const resetFilters = () => {
    setSearch("");
    setStatusFilter("");
    setSkillsetFilter("");
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
                  <TableCell sx={{ fontWeight: 600 }}>Icon</TableCell>
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
                    {Array.from({ length: 6 }).map((__, j) => (
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
                  <TableCell sx={{ fontWeight: 600 }}>Icon</TableCell>
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
                {filteredHabits.map((habit, index) => (
                  <TableRow
                    key={habit._id}
                    hover
                    sx={{
                      backgroundColor: index % 2 !== 0 ? "grey.50" : "inherit",
                    }}
                  >
                    <TableCell>
                      <span style={{ fontSize: 22 }}>{habit.icon}</span>
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
    </div>
  );
};

export default HabitList;
