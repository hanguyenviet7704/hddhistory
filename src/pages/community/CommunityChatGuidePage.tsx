import React, { useEffect, useState } from "react";
import {
  Button,
  IconButton,
  MenuItem,
  Skeleton,
  TextField,
  Tooltip,
} from "@mui/material";
import { PlusIcon, SaveIcon, Trash2Icon } from "lucide-react";

import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import { communityService } from "../../services/communityService";
import { ICommunityChatGuide } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

// The five languages the forum ships. A guide written in only some of them is
// normal — the app falls back to English rather than showing an empty sheet.
const LOCALES = [
  { value: "vi", label: "Tiếng Việt" },
  { value: "en", label: "English" },
  { value: "zh", label: "中文" },
  { value: "ja", label: "日本語" },
  { value: "ko", label: "한국어" },
];

type ListKey = "dos" | "donts" | "starters";

const emptyGuide = (locale: string): ICommunityChatGuide => ({
  locale,
  title: "",
  intro: "",
  dos: [],
  donts: [],
  starters: [],
});

/**
 * One of the three lists, with its own colour so the editor reads the way the
 * sheet does — green for what the room is for, red for what gets a line taken
 * down, neutral for the openers.
 */
const ListEditor: React.FC<{
  label: string;
  hint: string;
  tone: "do" | "dont" | "starter";
  items: string[];
  onChange: (items: string[]) => void;
}> = ({ label, hint, tone, items, onChange }) => {
  const toneClass = {
    do: "border-emerald-200 bg-emerald-50/60",
    dont: "border-rose-200 bg-rose-50/60",
    starter: "border-indigo-200 bg-indigo-50/60",
  }[tone];

  return (
    <div className={`space-y-3 rounded-xl border p-4 ${toneClass}`}>
      <div>
        <p className="text-sm font-semibold text-gray-900">{label}</p>
        <p className="text-xs text-gray-500">{hint}</p>
      </div>

      {items.map((item, index) => (
        <div key={index} className="flex items-start gap-2">
          <TextField
            fullWidth
            size="small"
            multiline
            value={item}
            onChange={(event) =>
              onChange(
                items.map((row, i) => (i === index ? event.target.value : row))
              )
            }
            className="bg-white"
          />
          <Tooltip title="Xoá dòng này">
            <IconButton
              aria-label={`Xoá dòng ${index + 1} của ${label}`}
              onClick={() => onChange(items.filter((_, i) => i !== index))}
            >
              <Trash2Icon size={16} />
            </IconButton>
          </Tooltip>
        </div>
      ))}

      {!items.length && (
        <p className="rounded-lg border border-dashed border-gray-300 bg-white/70 p-3 text-center text-xs text-gray-500">
          Chưa có dòng nào.
        </p>
      )}

      <Button
        size="small"
        variant="outlined"
        startIcon={<PlusIcon size={15} />}
        onClick={() => onChange([...items, ""])}
      >
        Thêm dòng
      </Button>
    </div>
  );
};

/**
 * "Hướng dẫn & nội quy nhóm" — the sheet behind the info button in the chat
 * header.
 *
 * Kept here rather than in the app's translation files because the rules are
 * the thing most likely to be reworded right after an incident, and that must
 * not wait for a release — nor be written five times in YAML and regenerated
 * before anyone can read it.
 *
 * One language at a time on purpose: writing house rules is writing, and a form
 * showing five columns of it side by side is a form nobody finishes.
 */
const CommunityChatGuidePage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [locale, setLocale] = useState("vi");
  const [guides, setGuides] = useState<Record<string, ICommunityChatGuide>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let alive = true;
    communityService
      .getChatGuides()
      .then((rows) => {
        if (!alive) return;
        setGuides(Object.fromEntries(rows.map((row) => [row.locale, row])));
      })
      .catch((err: any) =>
        showError(err?.response?.data?.message ?? "Không tải được nội quy")
      )
      .finally(() => alive && setLoading(false));

    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const current = guides[locale] ?? emptyGuide(locale);

  const patch = (next: Partial<ICommunityChatGuide>) =>
    setGuides((all) => ({ ...all, [locale]: { ...current, ...next } }));

  const patchList = (key: ListKey) => (items: string[]) =>
    patch({ [key]: items } as Partial<ICommunityChatGuide>);

  const save = async () => {
    setSaving(true);
    try {
      // Blank lines are dropped rather than rejected: an empty row is what
      // "Thêm dòng" leaves behind when somebody changes their mind, not a
      // mistake worth an error message.
      const clean = (items: string[]) =>
        items.map((item) => item.trim()).filter(Boolean);

      const payload: ICommunityChatGuide = {
        locale,
        title: current.title.trim(),
        intro: current.intro.trim(),
        dos: clean(current.dos),
        donts: clean(current.donts),
        starters: clean(current.starters),
      };
      const saved = await communityService.saveChatGuide(payload);
      setGuides((all) => ({ ...all, [locale]: saved ?? payload }));
      showSuccess("Đã lưu nội quy nhóm");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không lưu được nội quy");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4 p-6">
        <Skeleton variant="text" width={280} height={38} />
        <Skeleton variant="rounded" height={420} />
      </div>
    );
  }

  const isWritten = (item?: ICommunityChatGuide) =>
    !!(item?.title || item?.dos?.length || item?.donts?.length);

  return (
    <div className="space-y-5 p-6">
      <CommunityPageHeader
        title="Nội quy nhóm chat"
        subtitle="Nội dung của bottom sheet sau nút thông tin ở đầu phòng chat. Ngôn ngữ nào chưa viết thì app hiển thị bản tiếng Anh."
      >
        <TextField
          select
          size="small"
          label="Ngôn ngữ"
          value={locale}
          onChange={(e) => setLocale(e.target.value)}
          className="min-w-[160px]"
        >
          {LOCALES.map((item) => (
            <MenuItem key={item.value} value={item.value}>
              {item.label}
              {isWritten(guides[item.value]) ? "" : " · trống"}
            </MenuItem>
          ))}
        </TextField>
        <Button
          variant="contained"
          startIcon={<SaveIcon size={16} />}
          disabled={saving}
          onClick={save}
        >
          Lưu
        </Button>
      </CommunityPageHeader>

      <div className="space-y-4 rounded-xl border border-gray-200 bg-white p-5">
        <TextField
          fullWidth
          size="small"
          label="Tiêu đề"
          placeholder="Nội quy nhóm MeUp"
          value={current.title}
          onChange={(e) => patch({ title: e.target.value })}
        />
        <TextField
          fullWidth
          multiline
          minRows={2}
          size="small"
          label="Câu mở đầu"
          placeholder="Nơi đóng góp cùng nhau phát triển, không phải nơi chứng minh ai giỏi hơn."
          value={current.intro}
          onChange={(e) => patch({ intro: e.target.value })}
        />

        <ListEditor
          label="Nên"
          hint="Phòng này để làm gì. Thiết kế dùng 4 dòng ngắn."
          tone="do"
          items={current.dos}
          onChange={patchList("dos")}
        />
        <ListEditor
          label="Không"
          hint="Thứ khiến một dòng bị gỡ. Thiết kế dùng 3 dòng."
          tone="dont"
          items={current.donts}
          onChange={patchList("donts")}
        />
        <ListEditor
          label="Chưa biết nói gì? Hãy thử:"
          hint="Câu mở lời cho người chưa biết bắt đầu từ đâu. Chạm vào là điền sẵn vào ô soạn."
          tone="starter"
          items={current.starters}
          onChange={patchList("starters")}
        />
      </div>
    </div>
  );
};

export default CommunityChatGuidePage;
