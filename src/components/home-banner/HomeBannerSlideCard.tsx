import React, { useRef, useState } from "react";
import { Autocomplete, Button, Switch, TextField } from "@mui/material";
import { Trash2 } from "lucide-react";

import { COUNTRY_OPTIONS, countryLabel } from "../../config/countries";
import { cloudflareService } from "../../services/cloudflareR2Service";
import { HomeBannerSlide } from "../../services/homeBannerService";
import {
  fromInputDateTime,
  LOCALE_OPTIONS,
  PromoCampaignStats,
  toInputDateTime,
} from "../../utils/promoCampaignForm";
import PromoCampaignStatsStrip from "../common/PromoCampaignStatsStrip";

interface Props {
  slide: HomeBannerSlide;
  /** 1-based, for the header only — the array position IS the display order. */
  position: number;
  /** From `slideStats[index]` — undefined for a slide added locally and never saved. */
  stats?: PromoCampaignStats;
  onChange: (patch: Partial<HomeBannerSlide>) => void;
  onRemove: () => void;
  /** Lifted so the page can block Save while any slide is still uploading. */
  onUploadingChange: (uploading: boolean) => void;
  onError: (message: string) => void;
  onSuccess: (message: string) => void;
}

/**
 * One slide row of the Home carousel editor: preview, image upload, link, market
 * targeting and its own switch.
 *
 * Owns nothing but its file input — the slide list lives in the page so drag
 * reordering and Save stay in one place.
 */
const HomeBannerSlideCard: React.FC<Props> = ({
  slide,
  position,
  stats,
  onChange,
  onRemove,
  onUploadingChange,
  onError,
  onSuccess,
}) => {
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const uploadImage = async (file: File) => {
    setUploading(true);
    onUploadingChange(true);
    try {
      const res = await cloudflareService.upload(file, {
        prefix: "",
        folder: "home-banner",
      });
      const url = res?.data?.data?.url;
      if (!url) throw new Error("Không nhận được URL ảnh");
      onChange({ imageUrl: url });
      onSuccess("Đã tải ảnh lên — bấm Lưu để áp dụng");
    } catch (e: any) {
      console.error(e);
      onError(
        e?.response?.data?.message || "Tải ảnh thất bại, vui lòng thử lại.",
      );
    } finally {
      setUploading(false);
      onUploadingChange(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  return (
    <div className="rounded-lg border border-gray-200 p-4">
      <div className="mb-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-gray-700">
            Slide {position}
          </span>
          <Switch
            size="small"
            checked={slide.enabled}
            onChange={(e) => onChange({ enabled: e.target.checked })}
          />
          <span className="text-xs text-gray-500">
            {slide.enabled ? "Đang hiện" : "Đang tắt"}
          </span>
        </div>
        <Button
          size="small"
          color="error"
          startIcon={<Trash2 className="h-4 w-4" />}
          onClick={onRemove}
        >
          Xoá slide
        </Button>
      </div>

      <TextField
        label="Tên chiến dịch (nội bộ)"
        size="small"
        fullWidth
        value={slide.name ?? ""}
        onChange={(e) => onChange({ name: e.target.value })}
        helperText="Chỉ để nhận diện trong danh sách này, không hiện trên app."
      />

      <div className="h-4" />

      {/* Preview đúng tỉ lệ khung banner trong app: 390 × 78, bo góc 18 */}
      <div
        className="mb-2 w-full overflow-hidden bg-gray-100"
        style={{ aspectRatio: "390 / 78", borderRadius: 18 }}
      >
        {slide.imageUrl ? (
          <img
            src={slide.imageUrl}
            alt={`Slide ${position}`}
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full items-center justify-center text-xs text-gray-400">
            Chưa có ảnh — slide này sẽ không hiện trên app
          </div>
        )}
      </div>

      <div className="mb-4 flex items-center gap-3">
        <Button
          variant="outlined"
          size="small"
          component="label"
          disabled={uploading}
        >
          {uploading ? "Đang tải..." : "Tải ảnh lên"}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            hidden
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) uploadImage(file);
            }}
          />
        </Button>
        {slide.imageUrl && (
          <Button
            size="small"
            color="error"
            onClick={() => onChange({ imageUrl: "" })}
          >
            Gỡ ảnh
          </Button>
        )}
      </div>

      <TextField
        label="URL ảnh"
        size="small"
        fullWidth
        value={slide.imageUrl}
        onChange={(e) => onChange({ imageUrl: e.target.value })}
        helperText="Tự điền sau khi tải ảnh lên, hoặc dán URL ảnh có sẵn."
      />

      <div className="h-4" />

      <TextField
        label="Link khi bấm vào slide"
        size="small"
        fullWidth
        value={slide.linkUrl}
        onChange={(e) => onChange({ linkUrl: e.target.value })}
        helperText="URL https:// hoặc deeplink. Để trống thì slide chỉ hiển thị, không bấm được."
      />

      <div className="h-4" />

      <Autocomplete
        multiple
        size="small"
        options={COUNTRY_OPTIONS}
        // Stored codes may include ones outside the curated list (added straight
        // through the API, or from before an entry existed), so map through
        // `countryLabel` rather than assuming a match.
        value={slide.countries.map(
          (code) =>
            COUNTRY_OPTIONS.find((c) => c.code === code) ?? {
              code,
              name: countryLabel(code),
            },
        )}
        onChange={(_, selected) =>
          onChange({ countries: selected.map((c) => c.code) })
        }
        isOptionEqualToValue={(a, b) => a.code === b.code}
        getOptionLabel={(c) => `${c.name} (${c.code})`}
        renderInput={(params) => (
          <TextField
            {...params}
            label="Chỉ hiện với các thị trường"
            helperText="Để trống = hiện với mọi người. Khớp theo BẤT KỲ tín hiệu nào: IP, region của máy, hoặc ngôn ngữ app (chọn VN thì người Việt ở nước ngoài vẫn thấy)."
          />
        )}
      />

      <div className="h-4" />

      <Autocomplete
        multiple
        size="small"
        options={LOCALE_OPTIONS}
        value={(slide.locales ?? []).map(
          (code) => LOCALE_OPTIONS.find((l) => l.code === code) ?? { code, label: code },
        )}
        onChange={(_, selected) =>
          onChange({ locales: selected.map((l) => l.code) })
        }
        isOptionEqualToValue={(a, b) => a.code === b.code}
        getOptionLabel={(l) => l.label}
        renderInput={(params) => (
          <TextField
            {...params}
            label="Chỉ hiện với các ngôn ngữ"
            helperText="Để trống = hiện với mọi ngôn ngữ app đang chạy."
          />
        )}
      />

      <div className="h-4" />

      <div className="grid grid-cols-3 gap-3">
        <TextField
          label="Priority"
          type="number"
          size="small"
          value={slide.priority ?? 0}
          onChange={(e) =>
            onChange({
              priority: e.target.value === "" ? 0 : Number(e.target.value),
            })
          }
          helperText="Số cao hơn hiện trước."
        />
        <TextField
          label="Bắt đầu"
          type="datetime-local"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={toInputDateTime(slide.startAt)}
          onChange={(e) => onChange({ startAt: fromInputDateTime(e.target.value) })}
          helperText="Để trống = đã bắt đầu."
        />
        <TextField
          label="Kết thúc"
          type="datetime-local"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={toInputDateTime(slide.endAt)}
          onChange={(e) => onChange({ endAt: fromInputDateTime(e.target.value) })}
          helperText="Để trống = không hết hạn."
        />
      </div>

      <PromoCampaignStatsStrip stats={stats} />
    </div>
  );
};

export default HomeBannerSlideCard;
