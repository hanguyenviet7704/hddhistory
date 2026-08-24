import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  MenuItem,
  TextField,
} from "@mui/material";

interface Props {
  open: boolean;
  /** Prefilled when arriving from a post or comment row. */
  presetUserId?: string;
  saving?: boolean;
  onClose: () => void;
  onSubmit: (payload: {
    userId: string;
    mutedUntil?: string;
    reason: string;
  }) => void;
}

const DURATIONS = [
  { days: 7, label: "7 ngày" },
  { days: 30, label: "30 ngày" },
  { days: 0, label: "Vĩnh viễn" },
];

const CommunitySanctionModal: React.FC<Props> = ({
  open,
  presetUserId,
  saving,
  onClose,
  onSubmit,
}) => {
  const [userId, setUserId] = useState("");
  const [days, setDays] = useState(7);
  const [reason, setReason] = useState("");

  useEffect(() => {
    if (!open) return;
    setUserId(presetUserId ?? "");
    setDays(7);
    setReason("");
  }, [open, presetUserId]);

  const mutedUntil = () => {
    if (!days) return undefined;
    const until = new Date();
    until.setDate(until.getDate() + days);
    return until.toISOString();
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Khoá quyền đăng</DialogTitle>
      <DialogContent className="space-y-4">
        <DialogContentText>
          Người bị khoá vẫn đọc được cộng đồng, nhưng không đăng bài, bình luận,
          thả tim hay theo dõi chủ đề. App hiện đúng lý do bên dưới và ngày mở
          lại, nên hãy viết như một câu nói với người thật.
        </DialogContentText>
        <TextField
          fullWidth
          size="small"
          label="User ID"
          value={userId}
          onChange={(event) => setUserId(event.target.value)}
        />
        <TextField
          select
          fullWidth
          size="small"
          label="Thời hạn"
          value={days}
          onChange={(event) => setDays(Number(event.target.value))}
        >
          {DURATIONS.map((duration) => (
            <MenuItem key={duration.days} value={duration.days}>
              {duration.label}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          fullWidth
          multiline
          minRows={2}
          size="small"
          label="Lý do (gửi cho người dùng)"
          value={reason}
          onChange={(event) => setReason(event.target.value)}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          color="warning"
          disabled={saving || !userId.trim() || !reason.trim()}
          onClick={() =>
            onSubmit({
              userId: userId.trim(),
              mutedUntil: mutedUntil(),
              reason: reason.trim(),
            })
          }
        >
          Khoá
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CommunitySanctionModal;
