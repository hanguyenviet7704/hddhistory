// src/components/reanchor-reasons/ReanchorReasonConfirm.tsx
import React, { useState } from "react";
import {
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
} from "@mui/material";
import { IReanchorReason } from "../../types/interface/reanchor-reason.interface";
import { getTranslationValue } from "../../utils/translation";
import { LangCode } from "../../types/enum/common.enum";

interface Props {
  isOpen: boolean;
  reanchorReason?: IReanchorReason | null;
  onClose: () => void;
  onConfirm: () => Promise<void>;
}

export default function ReanchorReasonConfirm({
  isOpen,
  reanchorReason,
  onClose,
  onConfirm,
}: Props) {
  const [deleting, setDeleting] = useState(false);

  if (!reanchorReason) return null;

  const label =
    getTranslationValue(reanchorReason.reason, LangCode.EN) ||
    "this re-anchor reason";

  const handleDelete = async () => {
    setDeleting(true);
    try {
      await onConfirm();
    } finally {
      setDeleting(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>Delete re-anchor reason</DialogTitle>
      <DialogContent>
        <DialogContentText>
          Are you sure you want to delete "{label}"? This action cannot be
          undone.
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
          startIcon={
            deleting ? <CircularProgress size={16} color="inherit" /> : undefined
          }
        >
          Delete
        </Button>
      </DialogActions>
    </Dialog>
  );
}
