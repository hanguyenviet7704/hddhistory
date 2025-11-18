// src/components/skillsets/SkillsetList.tsx

import React, { useState, useEffect } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Box,
  Typography,
  Card,
  CardContent,
  Pagination,
  CircularProgress,
  Alert,
  Snackbar,
} from "@mui/material";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import {
  ISkillset,
  SkillsetListQuery,
  SkillsetPayload,
} from "../../types/interface/skillset.interface";
import { skillsetService } from "../../services/skillsetService";
import { CourseLevel, CourseStatus } from "../../types/enum/course.enum";
import { PencilIcon, PlusIcon, TrashIcon } from "lucide-react";
import SkillsetModal from "../../components/skillsets/SkillsetModal";
import SkillsetConfirm from "../../components/skillsets/SkillsetConfirm";
import { getTranslationValue } from "../../utils/translation";

// --- Component chính ---
const SkillsetList: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const [skillsets, setSkillsets] = useState<ISkillset[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState("");

  const [pagination, setPagination] = useState({
    page: 1,
    take: 10,
    total: 0,
  });

  // Dialog states
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  // Giữ nguyên state này theo yêu cầu
  const [currentSkillset, setCurrentSkillset] = useState<ISkillset>({
    _id: "",
    title: { [lang]: "" },
    description: { [lang]: "" },
    image: "",
  });

  // Notification state
  const [notification, setNotification] = useState({
    open: false,
    message: "",
    severity: "success" as "success" | "error",
  });

  // --- Gọi API để lấy danh sách skillset ---
  const fetchSkillsets = async (page = 1, search = "") => {
    setLoading(true);
    try {
      const params: Partial<SkillsetListQuery> = {
        page,
        take: pagination.take,
        search: search || undefined,
      };
      const response = await skillsetService.getList(params);
      setSkillsets(response.data.items || []);
      setPagination((prev) => ({
        ...prev,
        page,
        total: response.total || 0,
      }));
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // --- Các hàm xử lý sự kiện ---
  const handlePageChange = (
    event: React.ChangeEvent<unknown>,
    value: number
  ) => {
    fetchSkillsets(value, debouncedSearchTerm);
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchTerm(searchTerm);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    fetchSkillsets(1, debouncedSearchTerm);
  }, [debouncedSearchTerm]);

  const handleSkillsetSubmit = async (
    payload: SkillsetPayload,
    id?: string
  ) => {
    try {
      if (id) {
        await skillsetService.update(id, payload);
        setNotification({
          open: true,
          message: "Skillset updated successfully",
          severity: "success",
        });
        setEditDialogOpen(false);
      } else {
        await skillsetService.create(payload);
        setNotification({
          open: true,
          message: "Skillset created successfully",
          severity: "success",
        });
        setCreateDialogOpen(false);
      }
      fetchSkillsets(pagination.page, debouncedSearchTerm);
    } catch (err) {
      console.error(err);
      setNotification({
        open: true,
        message: `Failed to ${id ? "update" : "create"} skillset`,
        severity: "error",
      });
    }
  };

  const handleDeleteSkillset = (skillset: ISkillset) => {
    setCurrentSkillset(skillset);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteSkillset = () => {
    if (!currentSkillset) return;
    skillsetService
      .remove(currentSkillset._id)
      .then(() => {
        setNotification({
          open: true,
          message: "Skillset deleted successfully",
          severity: "success",
        });
        setDeleteDialogOpen(false);
        fetchSkillsets(pagination.page, debouncedSearchTerm);
      })
      .catch((err) => {
        console.error(err);
        setNotification({
          open: true,
          message: "Failed to delete skillset",
          severity: "error",
        });
      });
  };

  const openEditDialog = (skillset: ISkillset) => {
    setCurrentSkillset(skillset);
    setEditDialogOpen(true);
  };

  const closeNotification = () => {
    setNotification((prev) => ({ ...prev, open: false }));
  };

  const statusColors: Record<CourseStatus, string> = {
    [CourseStatus.PUBLISHED]: "bg-green-100 text-green-700",
    [CourseStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
    [CourseStatus.INACTIVE]: "bg-gray-200 text-gray-600",
  };

  const levelColors: Record<CourseLevel, string> = {
    [CourseLevel.LEVEL1]: "bg-blue-100 text-blue-700",
    [CourseLevel.LEVEL2]: "bg-purple-100 text-purple-700",
  };

  useEffect(() => {
    fetchSkillsets();
  }, []);

  // --- Render giao diện ---
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">🧩 Skillset</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative">
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search skillset..."
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
            <button
              onClick={() => setCreateDialogOpen(true)}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>New skillset</span>
            </button>
          </div>
        </div>
      </div>

      <div className="p-5">
        {loading ? (
          <div className="flex justify-center p-5">
            <CircularProgress />
          </div>
        ) : (
          <>
            <TableContainer
              component={Paper}
              elevation={3}
              sx={{ borderRadius: 2 }}
            >
              <Table>
                <TableHead
                  sx={{
                    backgroundColor: "white",
                    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                    transition: "all 0.3s ease",
                  }}
                >
                  <TableRow>
                    <TableCell
                      sx={{
                        fontWeight: 600,
                        fontSize: "1.1rem",
                        textShadow: "0 1px 2px rgba(0,0,0,0.15)",
                        transition: "all 0.3s ease",
                        width: "30%",
                      }}
                    >
                      Skillset
                    </TableCell>
                    <TableCell
                      sx={{
                        fontWeight: 600,
                        fontSize: "1.1rem",
                        textShadow: "0 1px 2px rgba(0,0,0,0.15)",
                        transition: "all 0.3s ease",
                        width: "70%",
                      }}
                    >
                      Courses
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {skillsets.map((skillset, index) => (
                    <TableRow
                      key={skillset._id}
                      sx={{
                        backgroundColor:
                          index % 2 !== 0 ? "grey.50" : "inherit",
                        "&:hover": { backgroundColor: "action.hover" },
                      }}
                    >
                      {/* Ô chứa thông tin Skillset */}
                      <TableCell sx={{ verticalAlign: "top" }}>
                        <Card variant="outlined" sx={{ mb: 2 }}>
                          <CardContent sx={{ display: "flex", p: 2 }}>
                            {/* Hình ảnh skillset */}
                            <Box
                              sx={{
                                width: "120px",
                                height: "120px",
                                overflow: "hidden",
                                borderRadius: 1,
                                flexShrink: 0,
                                mr: 2,
                              }}
                            >
                              <img
                                src={skillset.image}
                                alt={getTranslationValue(skillset.title, lang)}
                                style={{
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "cover",
                                }}
                              />
                            </Box>

                            {/* Nội dung skillset */}
                            <Box
                              sx={{
                                flex: 1,
                                display: "flex",
                                flexDirection: "column",
                              }}
                            >
                              <Typography
                                variant="h6"
                                component="div"
                                sx={{ fontWeight: "bold" }}
                                noWrap
                              >
                                {getTranslationValue(skillset.title, lang)}
                              </Typography>
                              <Typography
                                variant="body2"
                                color="text.secondary"
                                sx={{
                                  mb: 2,
                                  overflow: "hidden",
                                  textOverflow: "ellipsis",
                                  display: "-webkit-box",
                                  WebkitLineClamp: 2,
                                  WebkitBoxOrient: "vertical",
                                }}
                              >
                                {getTranslationValue(
                                  skillset.description,
                                  lang
                                )}
                              </Typography>
                              <Box sx={{ mt: "auto" }}>
                                <button
                                  onClick={() => openEditDialog(skillset)}
                                  title="Edit"
                                >
                                  <PencilIcon className="h-5 w-5 text-blue-600" />
                                </button>
                                <button
                                  onClick={() => handleDeleteSkillset(skillset)}
                                  title="Delete"
                                >
                                  <TrashIcon className="h-5 w-5 ml-2 text-red-600" />
                                </button>
                              </Box>
                            </Box>
                          </CardContent>
                        </Card>
                      </TableCell>

                      {/* Ô chứa danh sách tất cả các khóa học */}
                      <TableCell sx={{ verticalAlign: "top" }}>
                        {skillset.courses && skillset.courses.length > 0 ? (
                          <Box
                            sx={{
                              display: "flex",
                              flexDirection: "column",
                              gap: 2,
                            }}
                          >
                            {skillset.courses.map((course) => (
                              <Card key={course._id} variant="outlined">
                                <CardContent
                                  sx={{ pb: 2, "&:last-child": { pb: 2 } }}
                                >
                                  <Box
                                    sx={{
                                      display: "flex",
                                      flexDirection: "column",
                                      gap: 1,
                                    }}
                                  >
                                    <Typography
                                      variant="subtitle1"
                                      component="div"
                                      sx={{ fontWeight: "bold" }}
                                    >
                                      {getTranslationValue(course.title, lang)}
                                    </Typography>
                                    <Typography
                                      variant="body2"
                                      color="text.secondary"
                                    >
                                      {getTranslationValue(
                                        course.description,
                                        lang
                                      ) || "No description"}
                                    </Typography>
                                    <div className="flex justify-start gap-4 mb-3">
                                      <span
                                        className={`inline-block px-3 py-1 text-xs font-medium rounded-full ${
                                          statusColors[course.status]
                                        }`}
                                      >
                                        {course.status}
                                      </span>

                                      <span className="text-sm font-medium text-blue-500">
                                        {course.numberOfLesson || 0} lessons
                                      </span>
                                    </div>
                                  </Box>
                                </CardContent>
                              </Card>
                            ))}
                          </Box>
                        ) : (
                          <Typography
                            variant="body2"
                            color="text.secondary"
                            sx={{ fontStyle: "italic" }}
                          >
                            No courses available for this skillset.
                          </Typography>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {pagination.total > pagination.take && (
              <div className="flex justify-center mt-4">
                <Pagination
                  count={Math.ceil(pagination.total / pagination.take)}
                  page={pagination.page}
                  onChange={handlePageChange}
                  color="primary"
                />
              </div>
            )}
          </>
        )}

        {/* Create/Edit Skillset Modal */}
        <SkillsetModal
          isOpen={createDialogOpen || editDialogOpen}
          initial={editDialogOpen ? currentSkillset : null}
          onClose={() => {
            setCreateDialogOpen(false);
            setEditDialogOpen(false);
          }}
          onSubmit={handleSkillsetSubmit}
        />

        {/* Delete Skillset Confirmation */}
        <SkillsetConfirm
          isOpen={deleteDialogOpen}
          skillset={currentSkillset}
          onClose={() => setDeleteDialogOpen(false)}
          onConfirm={confirmDeleteSkillset}
        />

        {/* Notification Snackbar */}
        <Snackbar
          open={notification.open}
          autoHideDuration={6000}
          onClose={closeNotification}
        >
          <Alert
            onClose={closeNotification}
            severity={notification.severity}
            sx={{ width: "100%" }}
          >
            {notification.message}
          </Alert>
        </Snackbar>
      </div>
    </div>
  );
};

export default SkillsetList;
