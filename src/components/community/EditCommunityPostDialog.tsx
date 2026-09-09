import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
} from "@mui/material";

import { ICommunityAdminPost } from "../../types/interface/community.interface";

// Phải khớp với `CreateCommunityPostDto` phía API — một bài đã qua sửa vẫn
// nằm trong khung mà chính app dùng để tạo ra nó.
const MAX_SUBJECT_LENGTH = 160;
const MAX_BODY_LENGTH = 5000;
const MAX_IMAGES = 4;

export interface EditCommunityPostPayload {
  subject: string;
  body: string;
  images: string[];
}

interface Props {
  post: ICommunityAdminPost | null;
  saving?: boolean;
  onClose: () => void;
  onConfirm: (payload: EditCommunityPostPayload) => void;
}

/**
 * Sửa nội dung một bài đăng tại chỗ — xoá lời tục, sửa lỗi chính tả, gỡ một
 * tấm ảnh — không đi qua ẩn/hiện.
 *
 * Không đổi tác giả, ngôn ngữ, hay phòng: đây là sửa NỘI DUNG, không phải
 * viết lại bài với danh nghĩa khác. Đổi những thứ đó là việc của "Ẩn bài" +
 * để tác giả đăng lại, không phải của nút này.
 */
const EditCommunityPostDialog: React.FC<Props> = ({
  post,
  saving,
  onClose,
  onConfirm,
}) => {
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  // Một dòng một URL — cùng kiểu nhập tay đơn giản như ô ảnh của modal đăng
  // bài Đội ngũ MeUp, chỉ khác là cho phép nhiều dòng vì một bài đăng thường
  // có thể có tới 4 ảnh.
  const [imagesText, setImagesText] = useState("");

  useEffect(() => {
    if (!post) return;
    setSubject(post.subject ?? "");
    setBody(post.body);
    setImagesText((post.images ?? []).join("\n"));
  }, [post]);

  const images = imagesText
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .slice(0, MAX_IMAGES);

  const trimmedBody = body.trim();
  const canConfirm = !saving && trimmedBody.length > 0;

  return (
    <Dialog open={!!post} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Sửa bài đăng</DialogTitle>
      <DialogContent className="space-y-4">
        <DialogContentText>
          Tác giả không được báo là bài đã bị sửa — dùng cho lỗi chính tả, gỡ
          thông tin nhạy cảm, hoặc xoá một tấm ảnh, không phải viết lại bài
          thay tác giả.
        </DialogContentText>
        <TextField
          fullWidth
          size="small"
          label="Tiêu đề"
          value={subject}
          inputProps={{ maxLength: MAX_SUBJECT_LENGTH }}
          helperText={`${subject.length}/${MAX_SUBJECT_LENGTH} — để trống nếu bài này vốn không có tiêu đề`}
          onChange={(event) => setSubject(event.target.value)}
        />
        <TextField
          fullWidth
          multiline
          minRows={6}
          label="Nội dung"
          value={body}
          inputProps={{ maxLength: MAX_BODY_LENGTH }}
          helperText={`${body.length}/${MAX_BODY_LENGTH} — không được để trống`}
          error={!trimmedBody}
          onChange={(event) => setBody(event.target.value)}
        />
        <TextField
          fullWidth
          multiline
          minRows={2}
          size="small"
          label="Ảnh (URL, mỗi dòng một ảnh)"
          value={imagesText}
          helperText={`Tối đa ${MAX_IMAGES} ảnh — ${images.length}/${MAX_IMAGES} dòng hợp lệ`}
          onChange={(event) => setImagesText(event.target.value)}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          disabled={!canConfirm}
          onClick={() =>
            onConfirm({
              subject: subject.trim(),
              body: trimmedBody,
              images,
            })
          }
        >
          Lưu
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default EditCommunityPostDialog;
