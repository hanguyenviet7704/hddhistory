import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
} from "@mui/material";

import {
  ISegment,
  SegmentCriteria,
  SegmentPayload,
} from "../../types/interface/segment.interface";
import SegmentCriteriaForm from "./SegmentCriteriaForm";

interface Props {
  open: boolean;
  segment: ISegment | null;
  saving: boolean;
  onClose: () => void;
  onSubmit: (payload: SegmentPayload) => void;
}

const emptyCriteria = (): SegmentCriteria => ({
  firstSessionFrom: null,
  firstSessionTo: null,
  lastSessionFrom: null,
  lastSessionTo: null,
  languages: [],
  countries: [],
  deviceTypes: [],
  lifecycleFrom: null,
  lifecycleTo: null,
  userIds: [],
  userGoals: [],
  topicIds: [],
  userTypes: [],
});

/** Create/edit dialog: name + the full criteria builder. */
const SegmentFormDialog: React.FC<Props> = ({
  open,
  segment,
  saving,
  onClose,
  onSubmit,
}) => {
  const [name, setName] = useState("");
  const [nameTouched, setNameTouched] = useState(false);
  const [criteria, setCriteria] = useState<SegmentCriteria>(emptyCriteria());

  const isEdit = Boolean(segment);

  useEffect(() => {
    if (!open) return;
    setNameTouched(false);
    setName(segment?.name ?? "");
    setCriteria(
      segment?.criteria ? { ...emptyCriteria(), ...segment.criteria } : emptyCriteria(),
    );
  }, [open, segment]);

  const patchCriteria = (patch: Partial<SegmentCriteria>) =>
    setCriteria((prev) => ({ ...prev, ...patch }));

  const nameError = nameTouched && name.trim() === "";
  const lifecycleInvalid =
    criteria.lifecycleFrom != null &&
    criteria.lifecycleTo != null &&
    criteria.lifecycleTo < criteria.lifecycleFrom;

  const canSubmit = name.trim() !== "" && !lifecycleInvalid && !saving;

  const handleSubmit = () => {
    setNameTouched(true);
    if (!canSubmit) return;
    onSubmit({
      name: name.trim(),
      criteria: {
        ...criteria,
        // Round-tripped through a textarea (one id per line) — clean up here,
        // not per keystroke, so an in-progress blank line is not eaten.
        userIds: (criteria.userIds ?? []).map((id) => id.trim()).filter(Boolean),
      },
    });
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>{isEdit ? "Sửa phân khúc" : "Tạo phân khúc mới"}</DialogTitle>

      <DialogContent className="flex flex-col gap-4 pt-2">
        <TextField
          label="Tên phân khúc"
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => setNameTouched(true)}
          fullWidth
          autoFocus
          size="small"
          placeholder="Học viên VN mới, tuần đầu"
          error={nameError}
          helperText={nameError ? "Bắt buộc" : " "}
        />

        <SegmentCriteriaForm value={criteria} onChange={patchCriteria} />
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button variant="contained" onClick={handleSubmit} disabled={!canSubmit}>
          {saving ? "Đang lưu..." : "Lưu"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default SegmentFormDialog;
