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

/**
 * Canned reasons, so the note the author receives is a sentence rather than a
 * moderator's shorthand. Free text stays available for the cases these miss.
 */
const PRESETS = [
  "Nội dung vi phạm nội quy cộng đồng",
  "Nội dung quảng cáo / rao bán",
  "Nội dung tiết lộ danh tính người khác",
  "Nội dung xúc phạm, quấy rối người khác",
  "Nội dung không phù hợp (18+)",
  "Thông tin sai lệch",
];

interface Props {
  open: boolean;
  title: string;
  /** Shown above the field — say what will happen, not just what to type. */
  description: string;
  confirmLabel?: string;
  saving?: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
}

const ModerationReasonDialog: React.FC<Props> = ({
  open,
  title,
  description,
  confirmLabel = "Ẩn nội dung",
  saving,
  onClose,
  onConfirm,
}) => {
  const [reason, setReason] = useState(PRESETS[0]);
  const [custom, setCustom] = useState("");

  useEffect(() => {
    if (open) {
      setReason(PRESETS[0]);
      setCustom("");
    }
  }, [open]);

  const isCustom = reason === "__custom";
  const finalReason = isCustom ? custom.trim() : reason;

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>{title}</DialogTitle>
      <DialogContent className="space-y-4">
        <DialogContentText>{description}</DialogContentText>
        <TextField
          select
          fullWidth
          size="small"
          label="Lý do"
          value={reason}
          onChange={(event) => setReason(event.target.value)}
        >
          {PRESETS.map((preset) => (
            <MenuItem key={preset} value={preset}>
              {preset}
            </MenuItem>
          ))}
          <MenuItem value="__custom">Lý do khác…</MenuItem>
        </TextField>
        {isCustom && (
          <TextField
            fullWidth
            multiline
            minRows={2}
            size="small"
            label="Lý do gửi cho tác giả"
            value={custom}
            onChange={(event) => setCustom(event.target.value)}
          />
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          color="warning"
          disabled={saving || !finalReason}
          onClick={() => onConfirm(finalReason)}
        >
          {confirmLabel}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ModerationReasonDialog;
