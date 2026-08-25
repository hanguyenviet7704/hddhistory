import React, { useEffect, useMemo, useState } from "react";
import {
  Autocomplete,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
} from "@mui/material";

import { LangCode } from "../../types/enum/common.enum";
import {
  ICommunityRoomSuggestion,
  ICommunityTopic,
} from "../../types/interface/community.interface";
import { getTranslationValue } from "../../utils/translation";

interface Props {
  open: boolean;
  mode: "approve" | "decline";
  suggestion: ICommunityRoomSuggestion | null;
  topics: ICommunityTopic[];
  lang: LangCode;
  saving?: boolean;
  onClose: () => void;
  /** `topicId` is empty on decline. */
  onSubmit: (topicId: string, note: string) => void;
}

/**
 * Answering one ask for a room.
 *
 * Approving requires picking an EXISTING topic. Opening a room from here would
 * mean inventing a five-language name and a slug out of one line of free text,
 * so the flow is: create the room properly on the Topics screen, then come back
 * and point the ask at it. The copy says that, because otherwise the missing
 * "create room" button reads like a bug.
 */
const CommunityRoomSuggestionDialog: React.FC<Props> = ({
  open,
  mode,
  suggestion,
  topics,
  lang,
  saving,
  onClose,
  onSubmit,
}) => {
  const [topic, setTopic] = useState<ICommunityTopic | null>(null);
  const [note, setNote] = useState("");

  useEffect(() => {
    if (open) {
      setTopic(null);
      setNote("");
    }
  }, [open]);

  const options = useMemo(
    () => topics.filter((item) => item.isActive),
    [topics]
  );

  const isApprove = mode === "approve";
  const canSubmit = isApprove ? !!topic : true;

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>
        {isApprove ? "Mở phòng cho đề xuất này" : "Từ chối đề xuất"}
      </DialogTitle>
      <DialogContent className="space-y-4">
        {suggestion && (
          <div className="rounded-lg bg-gray-50 p-3">
            <div className="text-sm font-semibold">{suggestion.name}</div>
            {!!suggestion.description && (
              <div className="mt-1 text-xs text-gray-600">
                {suggestion.description}
              </div>
            )}
            <div className="mt-1 text-xs text-gray-500">
              {suggestion.voteCount} người ủng hộ ·{" "}
              {suggestion.locale.toUpperCase()}
            </div>
          </div>
        )}

        {isApprove ? (
          <>
            <DialogContentText className="text-sm">
              Chọn phòng đã tạo để gắn đề xuất này vào. Nếu chưa có, tạo phòng ở
              mục <strong>Chủ đề</strong> trước — một phòng cần tên đủ 5 ngôn ngữ
              và slug riêng, thứ mà đề xuất viết tay không có.
            </DialogContentText>
            <Autocomplete
              options={options}
              value={topic}
              onChange={(_, next) => setTopic(next)}
              getOptionLabel={(option) =>
                getTranslationValue(option.name, lang) || option.slug
              }
              isOptionEqualToValue={(option, value) =>
                option._id === value._id
              }
              renderInput={(params) => (
                <TextField {...params} size="small" label="Phòng" />
              )}
            />
          </>
        ) : (
          <DialogContentText className="text-sm">
            Đề xuất sẽ rời hàng đợi và không hiện cho người đọc nữa. Ghi chú chỉ
            để tụi mình đọc lại về sau.
          </DialogContentText>
        )}

        <TextField
          fullWidth
          multiline
          minRows={2}
          size="small"
          label="Ghi chú nội bộ (không bắt buộc)"
          value={note}
          onChange={(event) => setNote(event.target.value)}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          color={isApprove ? "success" : "inherit"}
          disabled={saving || !canSubmit}
          onClick={() => onSubmit(topic?._id ?? "", note.trim())}
        >
          {isApprove ? "Gắn vào phòng" : "Từ chối"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CommunityRoomSuggestionDialog;
