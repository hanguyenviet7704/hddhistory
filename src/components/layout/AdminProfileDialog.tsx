import React, { useEffect, useRef, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Skeleton,
  TextField,
} from "@mui/material";
import { UploadIcon, XIcon } from "lucide-react";

import { cloudflareService } from "../../services/cloudflareR2Service";
import { userService } from "../../services/userService";
import { useNotification } from "../../utils/hooks/useNotification";

interface Props {
  open: boolean;
  onClose: () => void;
}

/**
 * Hồ sơ của chính tài khoản đang đăng nhập.
 *
 * Trước đây nút "Profile" trên header mở ra đúng… không gì cả — `handleProfile`
 * chỉ đóng dropdown lại. Không có trang nào sửa được tên tài khoản admin, và
 * cũng không có trang quản lý Users, nên muốn đổi tên hiển thị thì phải vào
 * thẳng database.
 *
 * Đây KHÔNG phải "Đội ngũ MeUp" (trang riêng trong sidebar). Trang kia là danh
 * tính chung của đội khi đăng bài/trả lời với tư cách team; chỗ này là tên của
 * riêng tài khoản này — thứ hiện lên khi bạn nói với tư cách chính mình.
 */
const AdminProfileDialog: React.FC<Props> = ({ open, onClose }) => {
  const { showSuccess, showError } = useNotification();
  const userId =
    typeof window !== "undefined" ? localStorage.getItem("userId") : null;

  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState("");
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    if (!userId) {
      setLoading(false);
      showError("Không tìm thấy tài khoản đang đăng nhập");

      return;
    }

    let alive = true;
    setLoading(true);
    userService
      .getById(userId)
      .then((res: any) => {
        if (!alive) return;
        // Cùng cách bóc phong bì {statusCode, message, data} như Header đang
        // dùng — getById trả về body, nên user nằm ở `.data`.
        const data = res?.data?.data ?? res?.data ?? res;
        setName(data?.name ?? "");
        setAvatar(data?.avatar ?? "");
        setEmail(data?.email ?? "");
      })
      .catch((err: any) =>
        showError(err?.response?.data?.message ?? "Không tải được hồ sơ")
      )
      .finally(() => {
        if (alive) setLoading(false);
      });

    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, userId]);

  const upload = async (file: File) => {
    setUploading(true);
    try {
      const res = await cloudflareService.upload(file, {
        prefix: "",
        folder: "avatars",
      });
      const url = res?.data?.data?.url;
      if (!url) throw new Error("Không nhận được URL ảnh");
      setAvatar(url);
      showSuccess("Đã tải ảnh lên — bấm Lưu để áp dụng");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Tải ảnh thất bại");
    } finally {
      setUploading(false);
    }
  };

  const save = async () => {
    if (!userId) return;

    setSaving(true);
    try {
      // Chỉ gửi hai field này. `PUT /users/:id` nhận Partial nên field không
      // gửi thì giữ nguyên — đừng gửi cả object user đọc về, kẻo ghi đè những
      // thứ không định đụng tới.
      await userService.update(userId, {
        name: name.trim(),
        avatar: avatar.trim(),
      });
      showSuccess("Đã lưu hồ sơ");
      onClose();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không lưu được hồ sơ");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="xs">
      <DialogTitle>Hồ sơ của tôi</DialogTitle>
      <DialogContent className="space-y-4">
        {loading ? (
          <Skeleton variant="rounded" height={220} />
        ) : (
          <>
            <div className="flex items-center gap-4 pt-1">
              {avatar ? (
                <img
                  src={avatar}
                  alt=""
                  className="h-16 w-16 rounded-full border border-gray-200 object-cover"
                />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[#EBEAFD] text-xl font-bold text-[#4B44CA]">
                  {(name.trim()[0] ?? "?").toUpperCase()}
                </div>
              )}
              <div className="flex flex-col gap-2">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (file) upload(file);
                    event.target.value = "";
                  }}
                />
                <Button
                  size="small"
                  variant="outlined"
                  startIcon={<UploadIcon size={14} />}
                  disabled={uploading}
                  onClick={() => fileInputRef.current?.click()}
                >
                  {uploading ? "Đang tải..." : "Chọn ảnh"}
                </Button>
                {!!avatar && (
                  <Button
                    size="small"
                    color="inherit"
                    startIcon={<XIcon size={14} />}
                    onClick={() => setAvatar("")}
                  >
                    Bỏ ảnh
                  </Button>
                )}
              </div>
            </div>

            <TextField
              label="Tên hiển thị"
              size="small"
              fullWidth
              value={name}
              onChange={(event) => setName(event.target.value)}
              helperText="Tên này hiện ở MỌI nơi tài khoản xuất hiện — bình luận và tin nhắn bạn viết bằng tài khoản của mình, và cả hàng đợi kiểm duyệt. Muốn nói với tư cách đội ngũ thì dùng ô “với tư cách MeUp”, đừng đổi tên ở đây."
            />

            <TextField
              label="URL ảnh"
              size="small"
              fullWidth
              value={avatar}
              onChange={(event) => setAvatar(event.target.value)}
              helperText="Tải ảnh lên là tự điền. Dán URL sẵn có cũng được — nhớ encode dấu cách thành %20."
            />

            {!!email && (
              <TextField
                label="Email"
                size="small"
                fullWidth
                value={email}
                disabled
                helperText="Email đăng nhập, không sửa ở đây."
              />
            )}
          </>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          onClick={save}
          disabled={loading || saving || uploading || !name.trim()}
        >
          Lưu
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default AdminProfileDialog;
