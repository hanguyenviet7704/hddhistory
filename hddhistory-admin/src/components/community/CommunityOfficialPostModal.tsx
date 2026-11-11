import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  MenuItem,
  Switch,
  TextField,
} from "@mui/material";
import { useSelector } from "react-redux";

import { communityService } from "../../services/communityService";
import { RootState } from "../../store";
import {
  ICommunityOfficialPostPayload,
  ICommunityTopic,
} from "../../types/interface/community.interface";
import { getTranslationValue } from "../../utils/translation";
import { COMMUNITY_LANGS } from "./TranslationFields";

interface Props {
  open: boolean;
  saving?: boolean;
  onClose: () => void;
  onSubmit: (payload: ICommunityOfficialPostPayload) => void;
}

/**
 * Compose a post as "Đội ngũ HDDhistory".
 *
 * One locale per post, not a translation set: this lands in a feed alongside
 * readers' own posts, and those are single-language by nature. Posting the same
 * announcement to five feeds means five posts — which is also the only way the
 * pin, the comments and the reactions stay separate per language.
 */
const CommunityOfficialPostModal: React.FC<Props> = ({
  open,
  saving,
  onClose,
  onSubmit,
}) => {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [locale, setLocale] = useState<string>(lang);
  const [topicId, setTopicId] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [topics, setTopics] = useState<ICommunityTopic[]>([]);

  const loadTopics = useCallback(async () => {
    try {
      const res = await communityService.getTopics({ take: 100, isActive: true });
      setTopics(res?.items ?? []);
    } catch {
      // A failed topic list must not block the post — "không chọn nhóm" is a
      // valid choice anyway.
      setTopics([]);
    }
  }, []);

  useEffect(() => {
    if (!open) return;
    setSubject("");
    setBody("");
    setLocale(lang);
    setTopicId("");
    setImageUrl("");
    setIsPinned(false);
    loadTopics();
  }, [open, lang, loadTopics]);

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>Đăng bài với tư cách Đội ngũ HDDhistory</DialogTitle>
      <DialogContent className="space-y-4">
        <TextField
          fullWidth
          label="Tiêu đề"
          value={subject}
          inputProps={{ maxLength: 160 }}
          helperText="Dòng đậm hiện trên đầu thẻ bài trong feed"
          onChange={(event) => setSubject(event.target.value)}
        />
        <TextField
          fullWidth
          multiline
          minRows={5}
          label="Nội dung"
          value={body}
          onChange={(event) => setBody(event.target.value)}
        />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <TextField
            select
            size="small"
            label="Ngôn ngữ của feed"
            value={locale}
            helperText="Bài chỉ hiện với user dùng ngôn ngữ này"
            onChange={(event) => setLocale(event.target.value)}
          >
            {COMMUNITY_LANGS.map(({ code, label }) => (
              <MenuItem key={code} value={code}>
                {label}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            select
            size="small"
            label="Chủ đề"
            value={topicId}
            onChange={(event) => setTopicId(event.target.value)}
          >
            <MenuItem value="">Không chọn nhóm</MenuItem>
            {topics.map((topic) => (
              <MenuItem key={topic._id} value={topic._id}>
                {getTranslationValue(topic.name, lang)}
              </MenuItem>
            ))}
          </TextField>
        </div>
        <TextField
          fullWidth
          size="small"
          label="Ảnh (URL, tuỳ chọn)"
          value={imageUrl}
          onChange={(event) => setImageUrl(event.target.value)}
        />
        <FormControlLabel
          control={
            <Switch
              checked={isPinned}
              onChange={(event) => setIsPinned(event.target.checked)}
            />
          }
          label="Ghim lên đầu feed"
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          disabled={saving || !body.trim()}
          onClick={() =>
            onSubmit({
              subject: subject.trim() || undefined,
              body: body.trim(),
              locale,
              topicId: topicId || undefined,
              images: imageUrl.trim() ? [imageUrl.trim()] : undefined,
              isPinned,
            })
          }
        >
          Đăng
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CommunityOfficialPostModal;
