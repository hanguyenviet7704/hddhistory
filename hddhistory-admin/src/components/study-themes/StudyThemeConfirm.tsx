// src/components/study-themes/StudyThemeConfirm.tsx
import { useState } from "react";
import {
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from "@mui/material";
import { IStudyTheme } from "../../types/interface/study-theme.interface";

interface Props {
  open: boolean;
  theme: IStudyTheme | null;
  onClose: () => void;
  onConfirm: () => Promise<void>;
}

export default function StudyThemeConfirm({ open, theme, onClose, onConfirm }: Props) {
  const [deleting, setDeleting] = useState(false);

  if (!theme) return null;

  const handleDelete = async () => {
    setDeleting(true);
    try {
      await onConfirm();
      onClose();
    } catch (err) {
      // Parent already surfaces a notification for the failure; keep the
      // dialog open so the operator can retry or cancel.
      console.error("Delete study theme failed", err);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <Dialog open={open} onClose={() => !deleting && onClose()} maxWidth="xs" fullWidth>
      <DialogTitle>Delete study theme</DialogTitle>
      <DialogContent>
        <DialogContentText>
          Are you sure you want to delete "{theme.name}" ({theme.key})? This action
          cannot be undone. If it shipped in an app build already downloaded by
          users, it may keep appearing until they refresh the picker.
        </DialogContentText>
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} disabled={deleting}>
          Cancel
        </Button>
        <Button
          onClick={handleDelete}
          color="error"
          variant="contained"
          disabled={deleting}
          startIcon={deleting ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          Delete
        </Button>
      </DialogActions>
    </Dialog>
  );
}
