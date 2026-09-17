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
import {
  ICommunityChatGuide,
  ICommunityChatGuideSection,
} from "../../types/interface/community.interface";
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

const emptyGuide = (locale: string): ICommunityChatGuide => ({
  locale,
  title: "",
  intro: "",
  sections: [],
});

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
        setGuides(
          Object.fromEntries(rows.map((row) => [row.locale, row]))
        );
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

  const patchSection = (
    index: number,
    next: Partial<ICommunityChatGuideSection>
  ) =>
    patch({
      sections: current.sections.map((section, i) =>
        i === index ? { ...section, ...next } : section
      ),
    });

  const save = async () => {
    setSaving(true);
    try {
      // Blank sections are dropped rather than rejected: an empty row is what
      // "Thêm mục" leaves behind when somebody changes their mind, not a
      // mistake worth an error message.
      const sections = current.sections.filter(
        (section) => section.heading.trim() || section.body.trim()
      );
      const saved = await communityService.saveChatGuide({
        locale,
        title: current.title.trim(),
        intro: current.intro.trim(),
        sections,
      });
      setGuides((all) => ({ ...all, [locale]: saved ?? { ...current, sections } }));
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
              {guides[item.value]?.title ? "" : " · trống"}
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

        <div className="space-y-3">
          {current.sections.map((section, index) => (
            <div
              key={index}
              className="flex items-start gap-2 rounded-lg border border-gray-100 bg-gray-50 p-3"
            >
              <div className="flex-1 space-y-2">
                <TextField
                  fullWidth
                  size="small"
                  label={`Mục ${index + 1}`}
                  value={section.heading}
                  onChange={(e) =>
                    patchSection(index, { heading: e.target.value })
                  }
                />
                <TextField
                  fullWidth
                  multiline
                  minRows={2}
                  size="small"
                  label="Nội dung"
                  value={section.body}
                  onChange={(e) => patchSection(index, { body: e.target.value })}
                />
              </div>
              <Tooltip title="Xoá mục này">
                <IconButton
                  aria-label={`Xoá mục ${index + 1}`}
                  onClick={() =>
                    patch({
                      sections: current.sections.filter((_, i) => i !== index),
                    })
                  }
                >
                  <Trash2Icon size={16} />
                </IconButton>
              </Tooltip>
            </div>
          ))}

          {!current.sections.length && (
            <p className="rounded-lg border border-dashed border-gray-300 p-4 text-center text-sm text-gray-500">
              Chưa có mục nào. Nội quy thường là 3–5 mục ngắn.
            </p>
          )}
        </div>

        <Button
          variant="outlined"
          startIcon={<PlusIcon size={16} />}
          onClick={() =>
            patch({
              sections: [...current.sections, { heading: "", body: "" }],
            })
          }
        >
          Thêm mục
        </Button>
      </div>
    </div>
  );
};

export default CommunityChatGuidePage;
