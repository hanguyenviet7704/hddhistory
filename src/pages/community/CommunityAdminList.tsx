import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  Skeleton,
  TextField,
  Tooltip,
} from "@mui/material";
import { ShieldCheckIcon, Trash2Icon, UserPlusIcon } from "lucide-react";

import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import { communityService } from "../../services/communityService";
import { ICommunityAdminUser } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/**
 * Who may moderate from inside the app.
 *
 * The forum had no such notion until pinning arrived: every route treated any
 * valid token the same, and moderation happened only in this panel. Pinning is
 * the first action a MeUp person takes in the app itself, so somebody has to be
 * able to say who is staff — and without this page the only way was editing
 * Mongo by hand.
 *
 * The role granted is the GLOBAL `ADMIN`, the same one the rest of the API
 * knows, not a community-only badge. The copy says so, because handing out a
 * role whose reach is wider than the page it is granted on is exactly how these
 * things go wrong.
 */
const CommunityAdminList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [admins, setAdmins] = useState<ICommunityAdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [email, setEmail] = useState("");
  const [granting, setGranting] = useState(false);
  const [revoking, setRevoking] = useState<ICommunityAdminUser | null>(null);

  const load = async () => {
    try {
      setAdmins(await communityService.getAdmins());
    } catch (err: any) {
      showError(
        err?.response?.data?.message ?? "Không tải được danh sách quản trị viên"
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const grant = async () => {
    const trimmed = email.trim();
    if (!trimmed) return;

    setGranting(true);
    try {
      // Email or id, the same pair the onboarding reset tool takes — whoever
      // is doing this has one of the two and rarely both.
      await communityService.grantAdmin(
        trimmed.includes("@") ? { email: trimmed } : { userId: trimmed }
      );
      setEmail("");
      await load();
      showSuccess("Đã cấp quyền quản trị viên");
    } catch (err: any) {
      showError(
        err?.response?.data?.message ??
          "Không cấp được quyền — kiểm tra lại email hoặc user ID"
      );
    } finally {
      setGranting(false);
    }
  };

  const revoke = async () => {
    if (!revoking) return;
    try {
      await communityService.revokeAdmin(revoking.id);
      await load();
      showSuccess("Đã thu hồi quyền quản trị viên");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không thu hồi được quyền");
    } finally {
      setRevoking(null);
    }
  };

  return (
    <div className="space-y-5 p-6">
      <CommunityPageHeader
        title="Quản trị viên"
        subtitle="Người được cấp quyền sẽ thấy nút Ghim tin nhắn trong phòng chat. Đây là quyền ADMIN chung của hệ thống, không riêng cộng đồng — cấp có cân nhắc."
      />

      <div className="flex flex-wrap items-center gap-2 rounded-xl border border-gray-200 bg-white p-4">
        <TextField
          size="small"
          label="Email hoặc user ID"
          placeholder="ten@eupgroup.net"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && grant()}
          className="min-w-[320px]"
        />
        <Button
          variant="contained"
          startIcon={<UserPlusIcon size={16} />}
          disabled={granting || !email.trim()}
          onClick={grant}
        >
          Cấp quyền
        </Button>
        <p className="w-full text-xs text-gray-500">
          Quyền có hiệu lực ngay ở lần gọi API tiếp theo — người được cấp không
          cần đăng nhập lại.
        </p>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white">
        {loading ? (
          <div className="space-y-2 p-4">
            <Skeleton variant="rounded" height={56} />
            <Skeleton variant="rounded" height={56} />
          </div>
        ) : !admins.length ? (
          <p className="p-8 text-center text-sm text-gray-500">
            Chưa có quản trị viên nào. Chưa ai ghim được tin nhắn cho tới khi
            cấp quyền ở trên.
          </p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {admins.map((admin) => (
              <li
                key={admin.id}
                className="flex items-center gap-3 px-4 py-3"
              >
                <ShieldCheckIcon size={18} className="text-indigo-500" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-gray-900">
                    {admin.name || "(chưa đặt tên)"}
                  </p>
                  <p className="truncate text-xs text-gray-500">
                    {admin.email || admin.id}
                  </p>
                </div>
                <Tooltip title="Thu hồi quyền">
                  <IconButton
                    aria-label={`Thu hồi quyền của ${admin.email || admin.id}`}
                    onClick={() => setRevoking(admin)}
                  >
                    <Trash2Icon size={16} />
                  </IconButton>
                </Tooltip>
              </li>
            ))}
          </ul>
        )}
      </div>

      <Dialog open={!!revoking} onClose={() => setRevoking(null)}>
        <DialogTitle>Thu hồi quyền quản trị viên?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            {revoking?.email || revoking?.id} sẽ không còn ghim được tin nhắn.
            Những tin đã ghim vẫn giữ nguyên.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRevoking(null)}>Huỷ</Button>
          <Button color="error" variant="contained" onClick={revoke}>
            Thu hồi
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default CommunityAdminList;
