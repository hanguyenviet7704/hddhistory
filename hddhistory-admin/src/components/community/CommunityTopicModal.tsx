import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Switch,
  TextField,
} from "@mui/material";

import {
  ICommunityTopic,
  ICommunityTopicPayload,
} from "../../types/interface/community.interface";
import { ITranslation } from "../../utils/translation";
import TranslationFields from "./TranslationFields";

interface Props {
  open: boolean;
  topic: ICommunityTopic | null;
  saving?: boolean;
  onClose: () => void;
  onSubmit: (payload: ICommunityTopicPayload) => void;
}

const slugify = (value: string) =>
  value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");

const CommunityTopicModal: React.FC<Props> = ({
  open,
  topic,
  saving,
  onClose,
  onSubmit,
}) => {
  const [name, setName] = useState<ITranslation>({});
  const [description, setDescription] = useState<ITranslation>({});
  const [slug, setSlug] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [sortOrder, setSortOrder] = useState(0);
  const [isActive, setIsActive] = useState(true);
  // Only auto-fill the slug while creating: changing it on an existing topic
  // would orphan nothing (posts store the id) but does break any link already
  // shared, so it stays a deliberate edit.
  const [slugTouched, setSlugTouched] = useState(false);

  useEffect(() => {
    if (!open) return;
    setName(topic?.name ?? {});
    setDescription(topic?.description ?? {});
    setSlug(topic?.slug ?? "");
    setImageUrl(topic?.imageUrl ?? "");
    setSortOrder(topic?.sortOrder ?? 0);
    setIsActive(topic?.isActive ?? true);
    setSlugTouched(!!topic);
  }, [open, topic]);

  const handleNameChange = (next: ITranslation) => {
    setName(next);
    if (!slugTouched) {
      setSlug(slugify(next.en || next.vi || ""));
    }
  };

  const canSave = !!name.en?.trim() && !!slug.trim();

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>{topic ? "Sửa chủ đề" : "Chủ đề mới"}</DialogTitle>
      <DialogContent className="space-y-5">
        <TranslationFields
          label="Tên chủ đề"
          value={name}
          onChange={handleNameChange}
          rows={1}
        />
        <TranslationFields
          label="Mô tả"
          value={description}
          onChange={setDescription}
          rows={2}
          hint="Đoạn giới thiệu hiện ở đầu trang chủ đề trong app."
        />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <TextField
            label="Slug"
            size="small"
            value={slug}
            helperText="Chỉ chữ thường, số và dấu gạch ngang"
            onChange={(event) => {
              setSlugTouched(true);
              setSlug(event.target.value);
            }}
          />
          <TextField
            label="Ảnh (URL)"
            size="small"
            value={imageUrl}
            onChange={(event) => setImageUrl(event.target.value)}
          />
          <TextField
            label="Thứ tự"
            size="small"
            type="number"
            value={sortOrder}
            onChange={(event) => setSortOrder(Number(event.target.value) || 0)}
          />
        </div>
        <FormControlLabel
          control={
            <Switch
              checked={isActive}
              onChange={(event) => setIsActive(event.target.checked)}
            />
          }
          label="Đang hoạt động (tắt thì app không hiện chủ đề này nữa)"
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          disabled={saving || !canSave}
          onClick={() =>
            onSubmit({
              name,
              description,
              slug: slug.trim(),
              imageUrl: imageUrl.trim() || undefined,
              sortOrder,
              isActive,
            })
          }
        >
          Lưu
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CommunityTopicModal;
