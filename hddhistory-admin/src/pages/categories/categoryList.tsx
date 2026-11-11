// src/components/categories/CategoryList.tsx

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
  ICategory,
  CategoryListQuery,
  CategoryPayload,
} from "../../types/interface/category.interface";
import { categoryService } from "../../services/categoryService";
import {
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from "../../types/enum/category.enum";
import { CourseStatus } from "../../types/enum/course.enum";
import { PencilIcon, PlusIcon, TrashIcon } from "lucide-react";
import CategoryModal from "../../components/categories/CategoryModal";
import CategoryConfirm from "../../components/categories/CategoryConfirm";
import { getTranslationValue } from "../../utils/translation";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import { useNavigate } from "react-router-dom";

// --- Component chính ---
const onboardingIntroduceLabels = new Set(
  Object.values(CategoryOnboardingIntroduce)
);

const CategoryList: React.FC = () => {
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);
  const [categories, setCategories] = useState<ICategory[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<CategoryStatus | "">("");
  const [indexDrafts, setIndexDrafts] = useState<Record<string, string>>({});
  const [indexSaving, setIndexSaving] = useState<Record<string, boolean>>({});

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
  const [currentCategory, setCurrentCategory] = useState<ICategory>({
    _id: "",
    title: { [lang]: "" },
    description: { [lang]: "" },
    image: "",
    status: CategoryStatus.DRAFT,
  });

  // Notification state
  const [notification, setNotification] = useState({
    open: false,
    message: "",
    severity: "success" as "success" | "error",
  });

  // --- Gọi API để lấy danh sách chủ đề ---
  const fetchCategories = async (page = 1, search = "", status = "") => {
    setLoading(true);
    try {
      const params: Partial<CategoryListQuery> = {
        page,
        take: pagination.take,
        search: search || undefined,
        ...(status && { status: status as CategoryStatus }),
        isAll: true,
      };
      const response = await categoryService.getList(params);
      setCategories(response.data.items || []);
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
    _event: React.ChangeEvent<unknown>,
    value: number
  ) => {
    fetchCategories(value, debouncedSearchTerm, statusFilter);
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearchTerm(searchTerm);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    fetchCategories(1, debouncedSearchTerm, statusFilter);
  }, [debouncedSearchTerm, statusFilter]);

  const handleCategorySubmit = async (
    payload: CategoryPayload,
    id?: string
  ) => {
    try {
      if (id) {
        await categoryService.update(id, payload);
        setNotification({
          open: true,
          message: "Category updated successfully",
          severity: "success",
        });
        setEditDialogOpen(false);
      } else {
        await categoryService.create(payload);
        setNotification({
          open: true,
          message: "Category created successfully",
          severity: "success",
        });
        setCreateDialogOpen(false);
      }
      fetchCategories(pagination.page, debouncedSearchTerm);
    } catch (err) {
      console.error(err);
      setNotification({
        open: true,
        message: `Failed to ${id ? "update" : "create"} category`,
        severity: "error",
      });
    }
  };

  const handleDeleteCategory = (category: ICategory) => {
    setCurrentCategory(category);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteCategory = async () => {
    if (!currentCategory) return;
    try {
      await categoryService.remove(currentCategory._id);
      setNotification({
        open: true,
        message: "Category deleted successfully",
        severity: "success",
      });
      setDeleteDialogOpen(false);
      await fetchCategories(pagination.page, debouncedSearchTerm);
    } catch (err) {
      console.error(err);
      setNotification({
        open: true,
        message: "Failed to delete category",
        severity: "error",
      });
      throw err;
    }
  };

  const openEditDialog = (category: ICategory) => {
    setCurrentCategory(category);
    setEditDialogOpen(true);
  };

  const closeNotification = () => {
    setNotification((prev) => ({ ...prev, open: false }));
  };

  const statusColors: Record<CourseStatus | CategoryStatus, string> = {
    [CategoryStatus.PUBLISHED]: "bg-green-100 text-green-700",
    [CategoryStatus.DRAFT]: "bg-yellow-100 text-yellow-700",
    [CourseStatus.COMING_SOON]: "bg-brand-100 text-brand-700",
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    const nextDrafts: Record<string, string> = {};
    categories.forEach((category) => {
      nextDrafts[category._id] =
        category.index !== undefined && category.index !== null
          ? String(category.index)
          : "";
    });
    setIndexDrafts(nextDrafts);
  }, [categories]);

  const handleIndexChange = (id: string, value: string) => {
    setIndexDrafts((prev) => ({ ...prev, [id]: value }));
  };

  const commitIndexChange = async (category: ICategory) => {
    const rawValue = indexDrafts[category._id] ?? "";
    const trimmedValue = rawValue.trim();
    const currentIndex =
      category.index !== undefined && category.index !== null
        ? category.index
        : undefined;

    if (trimmedValue === "") {
      if (currentIndex === undefined) return;
      setIndexDrafts((prev) => ({
        ...prev,
        [category._id]: String(currentIndex),
      }));
      return;
    }

    const parsedIndex = Number(trimmedValue);

    if (Number.isNaN(parsedIndex)) {
      setNotification({
        open: true,
        message: "Index must be a number",
        severity: "error",
      });
      setIndexDrafts((prev) => ({
        ...prev,
        [category._id]:
          category.index !== undefined && category.index !== null
            ? String(category.index)
            : "",
      }));
      return;
    }

    if (parsedIndex === currentIndex) return;

    setIndexSaving((prev) => ({ ...prev, [category._id]: true }));
    try {
      await categoryService.update(category._id, { index: parsedIndex });
      setNotification({
        open: true,
        message: "Index updated successfully",
        severity: "success",
      });
      await fetchCategories(pagination.page, debouncedSearchTerm, statusFilter);
    } catch (err) {
      console.error(err);
      setNotification({
        open: true,
        message: "Failed to update index",
        severity: "error",
      });
      setIndexDrafts((prev) => ({
        ...prev,
        [category._id]:
          category.index !== undefined && category.index !== null
            ? String(category.index)
            : "",
      }));
    } finally {
      setIndexSaving((prev) => ({ ...prev, [category._id]: false }));
    }
  };

  // --- Render giao diện ---
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">🧩 Category</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative">
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search category..."
                className="w-full md:w-72 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
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
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as CategoryStatus | "")
              }
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
            >
              <option value="">All Status</option>
              <option value={CategoryStatus.DRAFT}>Draft</option>
              <option value={CategoryStatus.PUBLISHED}>Published</option>
            </select>
            <button
              onClick={() => setCreateDialogOpen(true)}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-brand-600 to-bronze-600 text-white px-4 py-2 rounded-lg hover:from-brand-700 hover:to-bronze-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>New category</span>
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
                        width: "40%",
                      }}
                    >
                      Category
                    </TableCell>
                    <TableCell
                      sx={{
                        fontWeight: 600,
                        fontSize: "1.1rem",
                        textShadow: "0 1px 2px rgba(0,0,0,0.15)",
                        transition: "all 0.3s ease",
                        width: "60%",
                      }}
                    >
                      Courses
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {categories.map((category, index) => (
                    <TableRow
                      key={category._id}
                      sx={{
                        backgroundColor:
                          index % 2 !== 0 ? "grey.50" : "inherit",
                        "&:hover": { backgroundColor: "action.hover" },
                      }}
                    >
                      {/* Ô chứa thông tin Chủ đề */}
                      <TableCell sx={{ verticalAlign: "top" }}>
                        <Card variant="outlined" sx={{ mb: 2 }}>
                          <CardContent sx={{ display: "flex", p: 2 }}>
                            {/* Hình ảnh chủ đề */}
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
                              <CloudflareAssetPreview
                                src={category.image}
                                alt={getTranslationValue(category.title, lang)}
                                style={{
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "cover",
                                }}
                              />
                            </Box>

                            {/* Nội dung chủ đề */}
                            <Box
                              sx={{
                                flex: 1,
                                display: "flex",
                                flexDirection: "column",
                                position: "relative",
                              }}
                            >
                              <Box
                                sx={{
                                  display: "flex",
                                  alignItems: "center",
                                  gap: 2,
                                }}
                              >
                                <Typography
                                  variant="h6"
                                  component="div"
                                  sx={{
                                    fontWeight: "bold",
                                    flex: 1,
                                    minWidth: 0,
                                  }}
                                  noWrap
                                >
                                  {getTranslationValue(category.title, lang)}
                                </Typography>
                                <div className="flex items-center gap-2">
                                  <span className="text-xs text-gray-500">
                                    Index
                                  </span>
                                  <input
                                    type="number"
                                    min={0}
                                    step={1}
                                    value={indexDrafts[category._id] ?? ""}
                                    onChange={(e) =>
                                      handleIndexChange(
                                        category._id,
                                        e.target.value
                                      )
                                    }
                                    onBlur={() => commitIndexChange(category)}
                                    onKeyDown={(e) => {
                                      if (e.key === "Enter") {
                                        e.preventDefault();
                                        (e.target as HTMLInputElement).blur();
                                      }
                                    }}
                                    disabled={!!indexSaving[category._id]}
                                    className="w-20 rounded-md border border-gray-300 px-2 py-1 text-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500 disabled:opacity-60"
                                  />
                                </div>
                              </Box>
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
                                  category.description,
                                  lang
                                )}
                              </Typography>
                              {category.onboardingIntroduce &&
                                onboardingIntroduceLabels.has(
                                  category.onboardingIntroduce
                                ) && (
                                  <Typography
                                    variant="body2"
                                    sx={{
                                      mb: 2,
                                      fontStyle: "italic",
                                      color: "text.secondary",
                                      opacity: 0.72,
                                    }}
                                  >
                                    {category.onboardingIntroduce}
                                  </Typography>
                                )}

                              {/* Status Badge ở góc dưới bên phải */}
                              <Box
                                sx={{
                                  position: "absolute",
                                  bottom: 8,
                                  right: 8,
                                }}
                              >
                                <span
                                  className={`inline-block px-3 py-1 text-xs font-medium rounded-full ${
                                    statusColors[category.status]
                                  }`}
                                >
                                  {category.status}
                                </span>
                              </Box>

                              <Box sx={{ mt: "auto" }}>
                                <button
                                  onClick={() => openEditDialog(category)}
                                  title="Edit"
                                >
                                  <PencilIcon className="h-5 w-5 text-brand-600" />
                                </button>
                                <button
                                  onClick={() => handleDeleteCategory(category)}
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
                        {category.courses && category.courses.length > 0 ? (
                          <Box
                            sx={{
                              display: "flex",
                              flexDirection: "column",
                              gap: 2,
                            }}
                          >
                            {category.courses.map((course) => (
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
                                      sx={{
                                        fontWeight: "bold",
                                        cursor: "pointer",
                                        "&:hover": { color: "primary.main" },
                                      }}
                                      onClick={() =>
                                        navigate(`/course/${course._id}`)
                                      }
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

                                      <span className="text-sm font-medium text-brand-500">
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
                            No courses available for this category.
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

        {/* Create/Edit Category Modal */}
        <CategoryModal
          isOpen={createDialogOpen || editDialogOpen}
          initial={editDialogOpen ? currentCategory : null}
          onClose={() => {
            setCreateDialogOpen(false);
            setEditDialogOpen(false);
          }}
          onSubmit={handleCategorySubmit}
        />

        {/* Delete Category Confirmation */}
        <CategoryConfirm
          isOpen={deleteDialogOpen}
          category={currentCategory}
          onClose={() => setDeleteDialogOpen(false)}
          onConfirm={confirmDeleteCategory}
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

export default CategoryList;
