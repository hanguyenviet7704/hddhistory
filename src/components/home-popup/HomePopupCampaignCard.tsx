import React, { useRef, useState } from "react";
import { Autocomplete, Button, Switch, TextField } from "@mui/material";
import { Trash2 } from "lucide-react";

import { COUNTRY_OPTIONS, countryLabel } from "../../config/countries";
import { cloudflareService } from "../../services/cloudflareR2Service";
import { HomePopupItem } from "../../services/homePopupService";
import { SegmentOption } from "../../types/interface/segment.interface";
import {
  fromInputDateTime,
  PromoCampaignStats,
  toInputDateTime,
} from "../../utils/promoCampaignForm";
import PromoCampaignStatsStrip from "../common/PromoCampaignStatsStrip";

interface Props {
  item: HomePopupItem;
  /** 1-based, for the header only — the array position IS the tie-break order. */
  position: number;
  /** From `popupStats[index]` — undefined for a campaign added locally and never saved. */
  stats?: PromoCampaignStats;
  /** Loaded ONCE by the page, shared across every campaign card. */
  segments: SegmentOption[];
  onChange: (patch: Partial<HomePopupItem>) => void;
  onRemove: () => void;
  /** Lifted so the page can block Save while any campaign is still uploading. */
  onUploadingChange: (uploading: boolean) => void;
  onError: (message: string) => void;
  onSuccess: (message: string) => void;
}

/**
 * One campaign card of the Home popup editor: preview, image upload, link,
 * market/segment targeting, schedule, its own switch, and its read-only
 * performance strip. (Language and priority stay server-side fields; the UI
 * dropped them 2026-08-14 — user call.)
 *
 * Owns nothing but its file input — the campaign list lives in the page so
 * drag reordering and Save stay in one place (mirrors `HomeBannerSlideCard`).
 */
const HomePopupCampaignCard: React.FC<Props> = ({
  item,
  position,
  stats,
  segments,
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
        folder: "home-popup",
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
            Chiến dịch {position}
          </span>
          <Switch
            size="small"
            checked={item.enabled ?? true}
            onChange={(e) => onChange({ enabled: e.target.checked })}
          />
          <span className="text-xs text-gray-500">
            {(item.enabled ?? true) ? "Đang hiện" : "Đang tắt"}
          </span>
        </div>
        <Button
          size="small"
          color="error"
          startIcon={<Trash2 className="h-4 w-4" />}
          onClick={onRemove}
        >
          Xoá chiến dịch
        </Button>
      </div>

      <TextField
        label="Tên chiến dịch (nội bộ)"
        size="small"
        fullWidth
        value={item.name ?? ""}
        onChange={(e) => onChange({ name: e.target.value })}
        helperText="Chỉ để nhận diện trong danh sách này, không hiện trên app."
      />

      <div className="h-4" />

      <p className="mb-2 text-sm font-medium text-gray-700">Ảnh popup</p>
      <div className="mb-2 w-full overflow-hidden rounded-xl bg-gray-100">
        {item.imageUrl ? (
          <img
            src={item.imageUrl}
            alt={`Chiến dịch ${position}`}
            className="max-h-56 w-full object-contain"
          />
        ) : (
          <div className="flex h-32 items-center justify-center text-xs text-gray-400">
            Chưa có ảnh — chiến dịch này sẽ không hiện trên app
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
        {item.imageUrl && (
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
        value={item.imageUrl}
        onChange={(e) => onChange({ imageUrl: e.target.value })}
        helperText="Bắt buộc. Ảnh hiện nguyên tỉ lệ (không crop) nên dùng ảnh dọc vừa phải, chữ nằm trong ảnh."
      />

      <div className="h-4" />

      <TextField
        label="Link khi bấm vào popup"
        size="small"
        fullWidth
        value={item.linkUrl ?? ""}
        onChange={(e) => onChange({ linkUrl: e.target.value })}
        helperText="URL https:// hoặc deeplink. Để trống thì popup chỉ để thông báo, bấm vào vẫn tính là đã xem và không hiện lại."
      />

      <div className="h-4" />

      <Autocomplete
        multiple
        size="small"
        options={COUNTRY_OPTIONS}
        value={(item.countries ?? []).map(
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
        options={segments}
        value={(item.segmentIds ?? []).map(
          (id) => segments.find((s) => s._id === id) ?? { _id: id, name: id },
        )}
        onChange={(_, selected) =>
          onChange({ segmentIds: selected.map((s) => s._id) })
        }
        isOptionEqualToValue={(a, b) => a._id === b._id}
        getOptionLabel={(s) => s.name}
        renderInput={(params) => (
          <TextField
            {...params}
            label="Chỉ hiện với các phân khúc user"
            helperText="Bỏ trống = mọi người dùng. Khớp BẤT KỲ phân khúc nào được chọn."
          />
        )}
      />

      <div className="h-4" />

      <div className="grid grid-cols-2 gap-3">
        <TextField
          label="Bắt đầu"
          type="datetime-local"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={toInputDateTime(item.startAt)}
          onChange={(e) => onChange({ startAt: fromInputDateTime(e.target.value) })}
          helperText="Để trống = đã bắt đầu."
        />
        <TextField
          label="Kết thúc"
          type="datetime-local"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={toInputDateTime(item.endAt)}
          onChange={(e) => onChange({ endAt: fromInputDateTime(e.target.value) })}
          helperText="Để trống = không hết hạn."
        />
      </div>

      <PromoCampaignStatsStrip stats={stats} />
    </div>
  );
};

export default HomePopupCampaignCard;
