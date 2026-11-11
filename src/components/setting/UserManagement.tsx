import { useEffect, useRef, useState } from "react";
import {
  ArrowDownTrayIcon,
  ArrowPathIcon,
  EyeIcon,
  PencilIcon,
  PlusIcon,
  TrashIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { Pagination } from "@mui/material";
import { useNavigate, useSearchParams } from "react-router-dom";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { IUser, UserListQuery } from "../../types/interface/user.interface";
import { UserRole, UserStatus } from "../../types/enum/user.enum";
import { userService } from "../../services/userService";
import { useNotification } from "../../utils/hooks/useNotification";
import { userProgressService } from "../../services/userProgressService";
import {
  coachProfileService,
  ICoachOnboardingProfile,
} from "../../services/coachProfileService";
import { UserProgressExportStatus } from "../../types/enum/user-progress.enum";

const PAGE_SIZE = 10;

const defaultUserForm: Partial<IUser> = {
  name: "",
  email: "",
  phone: "",
  age: "",
  gender: "",
  language: "",
  country: "",
  avatar: "",
  role: UserRole.USER,
  status: UserStatus.ACTIVE,
  provider: "",
  enery: "",
};

const SUBMIT_FIELDS: (keyof IUser)[] = [
  "name",
  "email",
  "phone",
  "age",
  "gender",
  "status",
  "language",
  "country",
  "avatar",
  "role",
  "enery",
];

const statusStyles: Record<UserStatus, string> = {
  [UserStatus.ACTIVE]: "bg-green-100 text-green-700",
  [UserStatus.IN_ACTIVE]: "bg-gray-100 text-gray-600",
};

const roleStyles: Record<UserRole, string> = {
  [UserRole.ADMIN]: "bg-purple-100 text-purple-700",
  [UserRole.USER]: "bg-brand-100 text-brand-700",
};

const getUserId = (user: Partial<IUser>) =>
  (user as any)._id || (user as any).id || "";

const getUserLabel = (user: Partial<IUser>) => user.name || user.email || "";

const formatLastActionValue = (lastAction?: IUser["lastAction"]) => {
  if (!lastAction) return "-";
  const timeText = lastAction.time
    ? new Date(lastAction.time).toLocaleString()
    : "";
  if (lastAction.action && timeText)
    return `${lastAction.action} @ ${timeText}`;
  if (lastAction.action) return lastAction.action;
  return timeText || "-";
};

const formatDevicesValue = (devices?: IUser["devices"]) => {
  if (!devices || devices.length === 0) return "No devices";
  // Marks which devices are actually reachable by push. "1 device (iPhone)" alone
  // hid the thing you need when a notification does not arrive: a device row
  // exists for every login, but only one carrying a pushToken can be sent to.
  const names = devices
    .map((d) => {
      const label = d.deviceName || d.deviceId || "?";
      if (!d.pushToken) return `${label} · chưa có push`;
      return d.pushEnabled === false
        ? `${label} · push TẮT trong app`
        : `${label} · push OK`;
    })
    .filter(Boolean)
    .join(", ");
  return `${devices.length} device${devices.length > 1 ? "s" : ""}${
    names ? ` (${names})` : ""
  }`;
};

const formatCreatedAtValue = (createdAt?: IUser["createdAt"]) => {
  if (!createdAt) return "-";
  const parsedDate = new Date(createdAt);
  if (Number.isNaN(parsedDate.getTime())) return "-";
  return parsedDate.toLocaleString("vi-VN", { hour12: false });
};

const InfoField = ({ label, value }: { label: string; value: string }) => (
  <div className="p-3 rounded border border-gray-200 bg-gray-50">
    <div className="text-xs uppercase text-gray-500 font-semibold">{label}</div>
    <div className="text-sm text-gray-800 mt-1">{value || "-"}</div>
  </div>
);

const triggerDownload = (url: string) => {
  const link = document.createElement("a");
  link.href = url;
  link.rel = "noopener";
  link.target = "_blank";
  link.download = "";
  document.body.appendChild(link);
  link.click();
  link.remove();
};

const UserManagement = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const { showSuccess, showError } = useNotification();
  const initialPageParam = Number(searchParams.get("page") || 1);
  const initialPage =
    Number.isNaN(initialPageParam) || initialPageParam < 1
      ? 1
      : initialPageParam;
  const [users, setUsers] = useState<IUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(initialPage);
  const [totalPagesCount, setTotalPagesCount] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState<UserRole | "">("");
  const [statusFilter, setStatusFilter] = useState<UserStatus | "">("");
  const [anonymousFilter, setAnonymousFilter] = useState<"" | "true" | "false">(
    ""
  );
  const [exporting, setExporting] = useState(false);
  const [exportStatus, setExportStatus] =
    useState<UserProgressExportStatus | null>(null);
  const [exportFileUrl, setExportFileUrl] = useState("");
  const exportPollRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const exportSessionRef = useRef(0);

  const [isFormOpen, setIsFormOpen] = useState(false);
  const [formData, setFormData] = useState<Partial<IUser>>(defaultUserForm);
  const [editingUser, setEditingUser] = useState<IUser | null>(null);
  // What this reader told the AI Coach about themselves. Fetched when the
  // dialog opens rather than with the list: one request per user looked at,
  // not one per row rendered.
  const [coachProfile, setCoachProfile] =
    useState<ICoachOnboardingProfile | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [deletingUser, setDeletingUser] = useState<IUser | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchTerm.trim()), 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const initialLoadRef = useRef(true);

  useEffect(() => {
    if (initialLoadRef.current) {
      initialLoadRef.current = false;
      fetchUsers(page);
      return;
    }
    fetchUsers(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch, roleFilter, statusFilter, anonymousFilter]);

  const syncPageParam = (nextPage: number) => {
    const params = new URLSearchParams(searchParams);
    params.set("page", String(nextPage));
    setSearchParams(params, { replace: true });
  };

  const fetchUsers = async (pageNumber: number) => {
    try {
      setLoading(true);
      const anonymousValue =
        anonymousFilter === "true"
          ? true
          : anonymousFilter === "false"
          ? false
          : undefined;
      const params: Partial<UserListQuery> = {
        page: pageNumber,
        take: PAGE_SIZE,
        search: debouncedSearch || undefined,
        role: roleFilter || undefined,
        status: statusFilter || undefined,
        anonymous: anonymousValue,
      };
      const response = await userService.getList({
        ...params,
      });

      const parsedData = response?.data?.data ?? response?.data ?? response;
      const possibleList =
        parsedData?.items ??
        parsedData?.list ??
        parsedData?.users ??
        parsedData?.data ??
        [];
      const list = Array.isArray(parsedData)
        ? parsedData
        : Array.isArray(possibleList)
        ? possibleList
        : [];

      const totalPagesFromApi =
        parsedData?.totalPages ??
        parsedData?.pagination?.totalPages ??
        parsedData?.pagination?.total;
      const itemsPerPage =
        parsedData?.itemsPerPage ??
        parsedData?.take ??
        parsedData?.pagination?.take ??
        PAGE_SIZE;
      const totalFromApi =
        parsedData?.total ??
        parsedData?.pagination?.totalItems ??
        response?.total ??
        response?.data?.total;
      const computedTotalPages =
        totalPagesFromApi ||
        (totalFromApi ? Math.ceil(totalFromApi / itemsPerPage) : undefined) ||
        (itemsPerPage ? Math.ceil(list.length / itemsPerPage) : 1);
      const currentPage =
        parsedData?.currentPage ??
        parsedData?.page ??
        parsedData?.pagination?.page ??
        pageNumber;

      setUsers(list);
      setTotalPagesCount(Number(computedTotalPages) || 1);
      const nextPage = Number(currentPage) || pageNumber;
      setPage(nextPage);
      syncPageParam(nextPage);
    } catch (error) {
      console.error("Failed to fetch users", error);
      showError("Tải danh sách người dùng thất bại");
    } finally {
      setLoading(false);
    }
  };

  const openCreateForm = () => {
    setEditingUser(null);
    setFormData(defaultUserForm);
    setIsFormOpen(true);
  };

  const openEditForm = (user: IUser) => {
    setEditingUser(user);
    setFormData({
      ...defaultUserForm,
      ...user,
    });
    setCoachProfile(null);
    const userId = getUserId(user);
    if (userId) {
      // Never blocks the dialog and never raises: a reader who has not met the
      // Coach has no profile, and that is an empty section, not an error.
      coachProfileService
        .getByUser(userId)
        .then(setCoachProfile)
        .catch(() => setCoachProfile(null));
    }
    setIsFormOpen(true);
  };

  const closeForm = () => {
    setIsFormOpen(false);
    setEditingUser(null);
    setCoachProfile(null);
    setFormData(defaultUserForm);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const userId = editingUser ? getUserId(editingUser) : null;
    if (editingUser && !userId) {
      showError("Không tìm thấy ID người dùng để cập nhật");
      return;
    }

    try {
      setSubmitting(true);

      const payload: Partial<IUser> = {};
      SUBMIT_FIELDS.forEach((key) => {
        const value = (formData as any)[key];
        if (value !== undefined) {
          (payload as any)[key] = key === "anonymous" ? Boolean(value) : value;
        }
      });

      if (userId) {
        await userService.update(userId, payload);
        showSuccess("Cập nhật người dùng thành công");
      } else {
        await userService.create(payload as IUser);
        showSuccess("Tạo người dùng mới thành công");
      }

      closeForm();
      fetchUsers(page);
    } catch (error) {
      console.error("Save user failed", error);
      showError("Lưu người dùng thất bại");
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = (user: IUser) => {
    setDeletingUser(user);
  };

  const handleDelete = async () => {
    if (!deletingUser) return;
    const id = getUserId(deletingUser);
    if (!id) {
      showError("Không tìm thấy ID người dùng để xoá");
      return;
    }

    try {
      setDeleting(true);
      await userService.remove(id);
      showSuccess("Xoá người dùng thành công");
      setDeletingUser(null);

      const isLastItemOnPage = users.length === 1 && page > 1;
      const nextPage = isLastItemOnPage ? page - 1 : page;
      fetchUsers(nextPage);
    } catch (error) {
      console.error("Delete user failed", error);
      showError("Xoá người dùng thất bại");
    } finally {
      setDeleting(false);
    }
  };

  const clearExportPoll = () => {
    if (exportPollRef.current) {
      clearTimeout(exportPollRef.current);
      exportPollRef.current = null;
    }
  };

  const parseExportResponse = (res: any) => {
    const data = res?.data?.data ?? res?.data ?? res ?? {};
    const rawStatus = data.status ?? res?.status ?? res?.data?.status ?? null;
    const status =
      typeof rawStatus === "string" ? rawStatus.trim().toLowerCase() : rawStatus;
    const fileUrl = data.fileUrl ?? res?.fileUrl ?? res?.data?.fileUrl ?? "";
    return { status, fileUrl };
  };

  const scheduleExportPoll = (sessionId: number) => {
    clearExportPoll();
    exportPollRef.current = setTimeout(() => {
      exportPollRef.current = null;
      pollExportStatus(sessionId);
    }, 5000);
  };

  const handleExportResponse = (sessionId: number, res: any) => {
    if (sessionId !== exportSessionRef.current) return;
    const { status, fileUrl } = parseExportResponse(res);

    if (
      status === UserProgressExportStatus.PENDING ||
      status === UserProgressExportStatus.PROCESSING
    ) {
      setExportStatus(status);
      scheduleExportPoll(sessionId);
      return;
    }

    clearExportPoll();
    setExportStatus(null);
    setExporting(false);

    if (status === UserProgressExportStatus.COMPLETED) {
      if (!fileUrl) {
        showError("Không tìm thấy file xuất tiến độ");
        return;
      }
      setExportFileUrl(fileUrl);
      triggerDownload(fileUrl);
      return;
    }

    if (status === UserProgressExportStatus.FAILED) {
      showError("Xuất tiến độ thất bại");
    }
  };

  const pollExportStatus = async (sessionId: number) => {
    if (sessionId !== exportSessionRef.current) return;
    try {
      const res = await userProgressService.exportAllUserProgress();
      handleExportResponse(sessionId, res);
    } catch (error) {
      console.error("Export all user progress failed", error);
      if (sessionId !== exportSessionRef.current) return;
      clearExportPoll();
      setExportStatus(null);
      setExporting(false);
      showError("Xuất tiến độ thất bại");
    }
  };

  const handleExportAllProgress = async () => {
    if (exporting) return;
    exportSessionRef.current += 1;
    const sessionId = exportSessionRef.current;
    clearExportPoll();
    setExporting(true);
    setExportFileUrl("");
    setExportStatus(UserProgressExportStatus.PROCESSING);
    try {
      const res = await userProgressService.exportAllUserProgress();
      handleExportResponse(sessionId, res);
    } catch (error) {
      console.error("Export all user progress failed", error);
      if (sessionId !== exportSessionRef.current) return;
      clearExportPoll();
      setExportStatus(null);
      setExporting(false);
      setExportFileUrl("");
      showError("Xuất tiến độ thất bại");
    }
  };

  useEffect(() => {
    return () => {
      if (exportPollRef.current) {
        clearTimeout(exportPollRef.current);
        exportPollRef.current = null;
      }
    };
  }, []);

  const renderAvatar = (user: IUser) => {
    if (user.avatar) {
      return (
        <img
          src={user.avatar}
          alt={user.name}
          className="h-10 w-10 rounded-full object-cover border border-gray-200"
        />
      );
    }

    const fallback = user.name?.trim()?.charAt(0)?.toUpperCase() || "?";
    return (
      <div className="h-10 w-10 rounded-full bg-gray-100 text-gray-600 flex items-center justify-center font-semibold border border-gray-200">
        {fallback}
      </div>
    );
  };

  const isExportPending =
    exportStatus === UserProgressExportStatus.PENDING ||
    exportStatus === UserProgressExportStatus.PROCESSING;
  const showExportSpinner = exporting || isExportPending;
  const exportLabel = showExportSpinner
    ? "Đang tổng hợp kết quả"
    : exportFileUrl
    ? "Tải file"
    : "Tải tiến độ";
  const handleExportAction = () => {
    if (exportFileUrl) {
      triggerDownload(exportFileUrl);
      return;
    }
    handleExportAllProgress();
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold text-gray-900">User list</h2>
          <p className="text-sm text-gray-500">
            Quản lý avatar, thông tin, trạng thái, vai trò và quyền ẩn danh.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => fetchUsers(page)}
            className="inline-flex items-center justify-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 border border-gray-300 transition-colors"
            disabled={loading}
          >
            <ArrowPathIcon
              className={`h-5 w-5 mr-2 ${loading ? "animate-spin" : ""}`}
            />
            Làm mới
          </button>
          <button
            onClick={handleExportAction}
            className="inline-flex items-center justify-center px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
            disabled={showExportSpinner}
          >
            {showExportSpinner ? (
              <ArrowPathIcon className="h-5 w-5 mr-2 animate-spin" />
            ) : (
              <ArrowDownTrayIcon className="h-5 w-5 mr-2" />
            )}
            {exportLabel}
          </button>
          <button
            onClick={openCreateForm}
            className="inline-flex items-center justify-center px-4 py-2 bg-brand-600 text-white rounded-lg hover:bg-brand-700 transition-colors"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            Thêm người dùng
          </button>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 flex flex-wrap items-center gap-3">
        <div className="flex-1 min-w-[160px] max-w-xs">
          <input
            type="text"
            placeholder="Search user..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm"
          />
        </div>
        <div>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value as UserRole | "")}
            className="px-3 py-2 border border-gray-300 rounded-md bg-white focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm w-[140px]"
          >
            <option value="">role</option>
            {Object.values(UserRole).map((role) => (
              <option key={role} value={role}>
                {role}
              </option>
            ))}
          </select>
        </div>
        <div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as UserStatus | "")}
            className="px-3 py-2 border border-gray-300 rounded-md bg-white focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm w-[140px]"
          >
            <option value="">status</option>
            {Object.values(UserStatus).map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
        </div>
        <div>
          <select
            value={anonymousFilter}
            onChange={(e) =>
              setAnonymousFilter(e.target.value as "" | "true" | "false")
            }
            className="px-3 py-2 border border-gray-300 rounded-md bg-white focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm w-[140px]"
          >
            <option value="">Anony</option>
            <option value="true">Yes</option>
            <option value="false">No</option>
          </select>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {loading ? (
          <div className="p-10 flex items-center justify-center text-gray-500">
            Đang tải danh sách...
          </div>
        ) : users.length === 0 ? (
          <div className="p-10 text-center text-gray-500">
            Chưa có người dùng. Thêm người dùng mới để bắt đầu quản lý.
          </div>
        ) : (
          <div className="overflow-x-auto relative">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider sticky left-0 z-20 bg-gray-50 min-w-[120px]">
                    Avatar
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider sticky left-[120px] z-20 bg-gray-50 min-w-[200px]">
                    Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Email
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Created At
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Anonymous
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Provider
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider sticky right-0 z-20 bg-gray-50 min-w-[120px]">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {users.map((user) => {
                  const id = getUserId(user);
                  const canNavigate = Boolean(id);
                  return (
                    <tr key={id || user.email}>
                      <td className="px-6 py-4 whitespace-nowrap sticky left-0 bg-white z-10 min-w-[120px]">
                        {renderAvatar(user)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap sticky left-[120px] bg-white z-10 min-w-[200px]">
                        <div className="text-sm font-medium text-gray-900">
                          {user.name || "-"}
                        </div>
                        <div className="text-xs text-gray-500">
                          {user.phone || user.country || ""}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {user.email || "-"}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {formatCreatedAtValue(user.createdAt)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span
                          className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                            statusStyles[user.status || UserStatus.IN_ACTIVE]
                          }`}
                        >
                          {user.status || UserStatus.IN_ACTIVE}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span
                          className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                            roleStyles[user.role || UserRole.USER]
                          }`}
                        >
                          {user.role || UserRole.USER}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {user.anonymous ? "Yes" : "No"}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                        {user.provider || "-"}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2 sticky right-0 bg-white z-10 min-w-[140px]">
                        <button
                          onClick={() => {
                            if (!id) return;
                            navigate(`/progress/user/${id}`, {
                              state: { userLabel: getUserLabel(user) },
                            });
                          }}
                          disabled={!canNavigate}
                          className={`inline-flex items-center ${
                            canNavigate
                              ? "text-slate-600 hover:text-slate-900"
                              : "text-gray-300 cursor-not-allowed"
                          }`}
                          title="Xem tiến độ học"
                        >
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => openEditForm(user)}
                          className="text-bronze-600 hover:text-bronze-900 inline-flex items-center"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => confirmDelete(user)}
                          className="text-red-600 hover:text-red-900 inline-flex items-center"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        <div className="p-4 flex justify-end">
          <Pagination
            count={totalPagesCount}
            page={page}
            onChange={(_, value) => fetchUsers(value)}
            color="primary"
            shape="rounded"
          />
        </div>
      </div>

      {isFormOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          {/* Cao hơn khung nhìn thì CUỘN, đừng tràn ra ngoài. Panel không có
              trần chiều cao nên khi thêm mục "AI Coach" vào, hai nút Huỷ/Lưu
              bị đẩy khuất khỏi màn hình và không bấm được (owner 2026-09-05).
              Sửa ở panel chứ không ở mục mới: bất kỳ field nào thêm sau này
              cũng sẽ gặp đúng chuyện đó. */}
          <div className="bg-white w-full max-w-4xl rounded-lg shadow-xl p-6 relative max-h-[90vh] overflow-y-auto">
            <button
              onClick={closeForm}
              className="absolute top-3 right-3 p-2 text-gray-500 hover:text-gray-700"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>

            <h3 className="text-lg font-semibold text-gray-900 mb-1">
              {editingUser ? "Chỉnh sửa người dùng" : "Thêm người dùng"}
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              Cập nhật đầy đủ thông tin hồ sơ, trạng thái, vai trò và nhà cung
              cấp đăng nhập.
            </p>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="md:col-span-1">
                  <CloudflareFileUpload
                    initialUrl={formData.avatar}
                    onUrlChange={(url) =>
                      setFormData((prev) => ({ ...prev, avatar: url }))
                    }
                    label="Avatar"
                    uploadPayload={{ prefix: "", folder: "users" }}
                  />
                </div>
                <div className="md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Name
                    </label>
                    <input
                      type="text"
                      value={formData.name || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          name: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Email
                    </label>
                    <input
                      type="email"
                      value={formData.email || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          email: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Phone
                    </label>
                    <input
                      type="text"
                      value={formData.phone || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          phone: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Age
                    </label>
                    <input
                      type="text"
                      value={formData.age || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          age: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Gender
                    </label>
                    <input
                      type="text"
                      value={formData.gender || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          gender: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Language
                    </label>
                    <input
                      type="text"
                      value={formData.language || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          language: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Country
                    </label>
                    <input
                      type="text"
                      value={formData.country || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          country: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Timezone
                    </label>
                    {/* Read-only: the APP reports this on push registration, and it
                        is what decides when a scheduled notification fires. Typing
                        one here would set a send time the device never agreed to —
                        and an empty value is real information (that user is not
                        schedulable yet), not a blank to fill in. */}
                    <input
                      type="text"
                      readOnly
                      value={formData.timezone || ""}
                      placeholder="chưa có — app chưa đăng ký push"
                      title="Do app gửi lên khi đăng ký push. Trống = user này chưa nhận được thông báo định kỳ."
                      className="w-full px-3 py-2 border border-gray-200 bg-gray-50 text-gray-600 rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Enery
                    </label>
                    <input
                      type="text"
                      value={formData.enery || ""}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          enery: e.target.value,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Status
                    </label>
                    <select
                      value={formData.status || UserStatus.ACTIVE}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          status: e.target.value as UserStatus,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                    >
                      {Object.values(UserStatus).map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Role
                    </label>
                    <select
                      value={formData.role || UserRole.USER}
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          role: e.target.value as UserRole,
                        }))
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                    >
                      {Object.values(UserRole).map((role) => (
                        <option key={role} value={role}>
                          {role}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="flex items-center gap-3">
                    <InfoField
                      label="Anonymous"
                      value={String(
                        Boolean(
                          editingUser?.anonymous ?? formData.anonymous ?? false
                        )
                      )}
                    />
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <InfoField label="Provider" value={formData.provider || "-"} />
                <InfoField
                  label="Last action"
                  value={formatLastActionValue(formData.lastAction)}
                />
                <InfoField
                  label="Devices"
                  value={formatDevicesValue(formData.devices)}
                />
              </div>

              {editingUser && (
                <div>
                  <div className="text-sm font-semibold text-gray-700 mb-2">
                    AI Coach · người dùng tự nói về mình
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <InfoField
                      label="Muốn cải thiện điều gì nhất"
                      value={coachProfile?.goalText || "-"}
                    />
                    <InfoField
                      label="Điều đang cản nhiều nhất"
                      value={coachProfile?.barrierText || "-"}
                    />
                    <InfoField
                      label="Đang làm gì"
                      value={coachProfile?.currentPractice || "-"}
                    />
                    <InfoField
                      label="Cách học hợp"
                      value={coachProfile?.learningStyle || "-"}
                    />
                    <InfoField
                      label="Công việc"
                      value={
                        coachProfile?.occupationRaw ||
                        coachProfile?.occupation ||
                        "-"
                      }
                    />
                    <InfoField
                      label="Xong onboarding lúc"
                      value={
                        coachProfile?.onboardedAt
                          ? new Date(coachProfile.onboardedAt).toLocaleString(
                              "vi-VN",
                              { hour12: false },
                            )
                          : "-"
                      }
                    />
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={closeForm}
                  className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                  disabled={submitting}
                >
                  Huỷ
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-brand-600 text-white rounded-md hover:bg-brand-700 disabled:opacity-60"
                  disabled={submitting}
                >
                  {submitting ? "Đang lưu..." : "Lưu"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deletingUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-white rounded-lg shadow-lg w-full max-w-md p-6 relative">
            <button
              onClick={() => setDeletingUser(null)}
              className="absolute top-3 right-3 p-2 text-gray-500 hover:text-gray-700"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Xoá người dùng
            </h3>
            <p className="text-sm text-gray-600 mb-6">
              Bạn có chắc muốn xoá{" "}
              <span className="font-semibold text-gray-900">
                {deletingUser.name || deletingUser.email}
              </span>
              ?
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setDeletingUser(null)}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                disabled={deleting}
              >
                Huỷ
              </button>
              <button
                onClick={handleDelete}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-60"
                disabled={deleting}
              >
                {deleting ? "Đang xoá..." : "Xoá"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagement;
