// src/pages/habits/HabitList.tsx
import React, { useEffect, useMemo, useState } from "react";
import {
  Box,
  Button,
  Chip,
  IconButton,
  MenuItem,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
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

const statusChipProps: Record<
  HabitStatus,
  { label: string; color: "default" | "success" }
> = {
  [HabitStatus.DRAFT]: { label: "Draft", color: "default" },
  [HabitStatus.PUBLISHED]: { label: "Published", color: "success" },
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
  // lesson picker for `lessonIds` without re-fetching on every open.
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
    <Box className="p-6">
      <Box className="mb-4 flex items-center justify-between gap-3">
        <Typography variant="h5">Habits</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={openCreateModal}
        >
          Create habit
        </Button>
      </Box>

      <Box className="mb-4 flex flex-wrap items-center gap-3">
        <TextField
          size="small"
          label="Search title"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-64"
        />
        <TextField
          select
          size="small"
          label="Skillset"
          value={skillsetFilter}
          onChange={(e) => setSkillsetFilter(e.target.value)}
          className="w-56"
        >
          <MenuItem value="">All skillsets</MenuItem>
          {skillsets.map((skillset) => (
            <MenuItem key={skillset._id} value={skillset._id}>
              {getTranslationValue(skillset.title, lang)}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Status"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as HabitStatus | "")}
          className="w-40"
        >
          <MenuItem value="">All statuses</MenuItem>
          <MenuItem value={HabitStatus.DRAFT}>Draft</MenuItem>
          <MenuItem value={HabitStatus.PUBLISHED}>Published</MenuItem>
        </TextField>
      </Box>

      {loading ? (
        <TableContainer component={Paper} className="overflow-x-auto">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Icon</TableCell>
                <TableCell>Title</TableCell>
                <TableCell>Skillset</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Order</TableCell>
                <TableCell align="right">Actions</TableCell>
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
        <Paper className="p-6 text-center">
          <Typography color="error" className="mb-2">
            {error}
          </Typography>
          <Button variant="outlined" onClick={() => fetchHabits()}>
            Retry
          </Button>
        </Paper>
      ) : habits.length === 0 ? (
        <Paper className="p-6 text-center">
          <Typography className="mb-2">
            No habits yet — create the first one to power the mobile app's
            Habit feature.
          </Typography>
          <Button variant="contained" onClick={openCreateModal}>
            Create the first habit
          </Button>
        </Paper>
      ) : filteredHabits.length === 0 ? (
        <Paper className="p-6 text-center">
          <Typography className="mb-2">
            No habits match your filters.
          </Typography>
          <Button
            variant="outlined"
            disabled={!hasActiveFilters}
            onClick={resetFilters}
          >
            Reset filters
          </Button>
        </Paper>
      ) : (
        <TableContainer component={Paper} className="overflow-x-auto">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Icon</TableCell>
                <TableCell>Title</TableCell>
                <TableCell>Skillset</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Order</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredHabits.map((habit) => (
                <TableRow key={habit._id} hover>
                  <TableCell>
                    <Typography fontSize={22} component="span">
                      {habit.icon}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {getTranslationValue(habit.title, lang) || "—"}
                  </TableCell>
                  <TableCell>
                    {skillsetNameById.get(habit.skillsetId) ||
                      "Unknown skillset"}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={statusChipProps[habit.status].label}
                      color={statusChipProps[habit.status].color}
                    />
                  </TableCell>
                  <TableCell>{habit.order}</TableCell>
                  <TableCell align="right">
                    <IconButton
                      aria-label="Edit habit"
                      size="small"
                      onClick={() => openEditModal(habit)}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      aria-label="Delete habit"
                      size="small"
                      onClick={() => openDeleteConfirm(habit)}
                    >
                      <DeleteIcon fontSize="small" color="error" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

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
    </Box>
  );
};

export default HabitList;
