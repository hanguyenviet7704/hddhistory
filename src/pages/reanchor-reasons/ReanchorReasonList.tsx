// src/pages/reanchor-reasons/ReanchorReasonList.tsx
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
import { reanchorReasonService } from "../../services/reanchorReasonService";
import { courseService } from "../../services/courseService";
import {
  IReanchorReason,
  ReanchorReasonPayload,
} from "../../types/interface/reanchor-reason.interface";
import { ReanchorReasonStatus } from "../../types/enum/reanchor-reason.enum";
import { ICourse } from "../../types/interface/course.interface";
import { getTranslationValue } from "../../utils/translation";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";
import ReanchorReasonModal from "../../components/reanchor-reasons/ReanchorReasonModal";
import ReanchorReasonConfirm from "../../components/reanchor-reasons/ReanchorReasonConfirm";
import ExportImportButtons from "../../components/common/ExportImportButtons";
import {
  downloadReanchorXlsx,
  parseReanchorXlsx,
} from "../../utils/habitContentXlsx";

const statusLabels: Record<ReanchorReasonStatus, string> = {
  [ReanchorReasonStatus.DRAFT]: "Draft",
  [ReanchorReasonStatus.PUBLISHED]: "Published",
};

const statusStyles: Record<ReanchorReasonStatus, string> = {
  [ReanchorReasonStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
  [ReanchorReasonStatus.PUBLISHED]: "bg-green-100 text-green-700",
};

const ReanchorReasonList: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [reasons, setReasons] = useState<IReanchorReason[]>([]);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<ReanchorReasonStatus | "">(
    ""
  );
  const [courseFilter, setCourseFilter] = useState("");

  const [modalOpen, setModalOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IReanchorReason | null>(null);

  const courseNameById = useMemo(() => {
    const map = new Map<string, string>();
    courses.forEach((course) => {
      map.set(course._id, getTranslationValue(course.title, lang));
    });
    return map;
  }, [courses, lang]);

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
  // side. `courseId` is not affected by that rule and is still sent to
  // narrow the query server side.
  const fetchReasons = async (courseIdFilter = courseFilter) => {
    setLoading(true);
    setError(null);
    try {
      const response = await reanchorReasonService.getList({
        isAll: true,
        ...(courseIdFilter && { courseId: courseIdFilter }),
      });
      setReasons(response.data ?? []);
    } catch (err: any) {
      const message =
        err?.response?.data?.message ?? "Failed to load re-anchor reasons";
      setError(message);
      showError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourses();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    fetchReasons(courseFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseFilter]);

  const filteredReasons = useMemo(() => {
    return reasons.filter((item) => {
      if (statusFilter && item.status !== statusFilter) return false;
      if (search.trim()) {
        const term = search.trim().toLowerCase();
        // Search across every locale so a reason is findable regardless of
        // the language the admin is currently viewing.
        const matches = Object.values(item.reason ?? {}).some((value) =>
          (value ?? "").toLowerCase().includes(term)
        );
        if (!matches) return false;
      }
      return true;
    });
  }, [reasons, search, statusFilter]);

  const hasActiveFilters =
    !!search.trim() || !!statusFilter || !!courseFilter;

  const resetFilters = () => {
    setSearch("");
    setStatusFilter("");
    setCourseFilter("");
  };

  const openCreateModal = () => {
    setSelected(null);
    setModalOpen(true);
  };

  const openEditModal = (reason: IReanchorReason) => {
    setSelected(reason);
    setModalOpen(true);
  };

  const openDeleteConfirm = (reason: IReanchorReason) => {
    setSelected(reason);
    setConfirmOpen(true);
  };

  const handleSubmit = async (payload: ReanchorReasonPayload, id?: string) => {
    if (id) {
      await reanchorReasonService.update(id, payload);
      showSuccess("Re-anchor reason updated successfully");
    } else {
      await reanchorReasonService.create(payload);
      showSuccess("Re-anchor reason created successfully");
    }
    setModalOpen(false);
    await fetchReasons();
  };

  const handleDelete = async () => {
    if (!selected) return;
    try {
      await reanchorReasonService.remove(selected._id);
      showSuccess("Re-anchor reason deleted successfully");
      setConfirmOpen(false);
      setSelected(null);
      await fetchReasons();
    } catch (err: any) {
      showError(
        err?.response?.data?.message ?? "Failed to delete re-anchor reason"
      );
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">⚓ Re-anchor Reasons</h1>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search reason..."
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
                setStatusFilter(e.target.value as ReanchorReasonStatus | "")
              }
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
            >
              <option value="">All statuses</option>
              <option value={ReanchorReasonStatus.DRAFT}>Draft</option>
              <option value={ReanchorReasonStatus.PUBLISHED}>
                Published
              </option>
            </select>
            <ExportImportButtons
              label="re-anchor reasons"
              onExport={async () => {
                const rows = await reanchorReasonService.exportData();
                downloadReanchorXlsx(rows);
              }}
              onParse={parseReanchorXlsx}
              onImport={(rows) => reanchorReasonService.importData(rows)}
              onImported={() => fetchReasons()}
            />
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Create re-anchor reason</span>
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
                  <TableCell sx={{ fontWeight: 600 }}>Course</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Reason</TableCell>
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
            <p className="text-red-600 mb-3">{error}</p>
            <button
              onClick={() => fetchReasons()}
              className="inline-flex items-center gap-2 border border-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition"
            >
              Retry
            </button>
          </div>
        ) : reasons.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md p-8 text-center">
            <p className="text-gray-600 mb-3">
              No re-anchor reasons yet — create the first one to power the
              mobile app's "why did you pause?" prompt.
            </p>
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Create the first reason</span>
            </button>
          </div>
        ) : filteredReasons.length === 0 ? (
          <div className="bg-white rounded-xl shadow-md p-8 text-center">
            <p className="text-gray-600 mb-3">
              No re-anchor reasons match your filters.
            </p>
            <button
              disabled={!hasActiveFilters}
              onClick={resetFilters}
              className="inline-flex items-center gap-2 border border-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition disabled:opacity-50 disabled:cursor-not-allowed"
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
                  <TableCell sx={{ fontWeight: 600 }}>Course</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Reason</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Status</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Order</TableCell>
                  <TableCell sx={{ fontWeight: 600 }} align="right">
                    Actions
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredReasons.map((item, index) => (
                  <TableRow
                    key={item._id}
                    sx={{
                      backgroundColor: index % 2 !== 0 ? "grey.50" : "inherit",
                      "&:hover": { backgroundColor: "action.hover" },
                    }}
                  >
                    <TableCell>
                      {courseNameById.get(item.courseId) || "Unknown course"}
                    </TableCell>
                    <TableCell>
                      {getTranslationValue(item.reason, lang) || "—"}
                    </TableCell>
                    <TableCell>
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-xs font-medium inline-block ${
                          statusStyles[item.status]
                        }`}
                      >
                        {statusLabels[item.status]}
                      </span>
                    </TableCell>
                    <TableCell>{item.order}</TableCell>
                    <TableCell align="right">
                      <button
                        aria-label="Edit re-anchor reason"
                        onClick={() => openEditModal(item)}
                        className="p-2 rounded-full hover:bg-gray-100 transition-colors"
                      >
                        <PencilIcon className="h-4 w-4 text-blue-600" />
                      </button>
                      <button
                        aria-label="Delete re-anchor reason"
                        onClick={() => openDeleteConfirm(item)}
                        className="p-2 rounded-full hover:bg-gray-100 transition-colors"
                      >
                        <TrashIcon className="h-4 w-4 text-red-600" />
                      </button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </div>

      <ReanchorReasonModal
        isOpen={modalOpen}
        initial={selected}
        courses={courses}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
      />

      <ReanchorReasonConfirm
        isOpen={confirmOpen}
        reanchorReason={selected}
        onClose={() => {
          setConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={handleDelete}
      />
    </div>
  );
};

export default ReanchorReasonList;
