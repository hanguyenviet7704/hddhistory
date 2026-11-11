import React from "react";
import {
  Autocomplete,
  Checkbox,
  Divider,
  FormControlLabel,
  FormGroup,
  TextField,
  Typography,
} from "@mui/material";

import { SegmentCriteria } from "../../types/interface/segment.interface";
import {
  fromInputDateTime,
  LOCALE_OPTIONS,
  toInputDateTime,
} from "../../utils/promoCampaignForm";
import ChipInputField from "./ChipInputField";
import { DEVICE_TYPE_OPTIONS, USER_TYPE_OPTIONS } from "./segmentCriteria.utils";

interface Props {
  value: SegmentCriteria;
  onChange: (patch: Partial<SegmentCriteria>) => void;
}

const HINT = "Bỏ trống = không lọc theo tiêu chí này.";

function toggle<T>(list: T[] | undefined, item: T): T[] {
  const current = list ?? [];
  return current.includes(item)
    ? current.filter((v) => v !== item)
    : [...current, item];
}

/** Only true integer text — reject "1.5", "abc", empty. */
const isInteger = (raw: string) => /^-?\d+$/.test(raw.trim());

/**
 * The whole criteria block for one segment: every field optional, unset =
 * unfiltered. Grouped into the same sections the API groups them into
 * (`SegmentCriteriaDto`), each with its own "what this means" hint so an
 * operator does not have to guess the semantics of an empty field.
 */
const SegmentCriteriaForm: React.FC<Props> = ({ value, onChange }) => {
  return (
    <div className="flex flex-col gap-5">
      <section>
        <Typography variant="subtitle2" className="mb-1">
          Thời gian sử dụng
        </Typography>
        <p className="mb-2 text-xs text-gray-500">
          Thời điểm thiết bị liên lạc với server lần đầu / lần gần nhất. {HINT}
        </p>
        <div className="grid grid-cols-2 gap-3">
          <TextField
            label="Lần đầu — từ"
            type="datetime-local"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={toInputDateTime(value.firstSessionFrom)}
            onChange={(e) =>
              onChange({ firstSessionFrom: fromInputDateTime(e.target.value) })
            }
          />
          <TextField
            label="Lần đầu — đến"
            type="datetime-local"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={toInputDateTime(value.firstSessionTo)}
            onChange={(e) =>
              onChange({ firstSessionTo: fromInputDateTime(e.target.value) })
            }
          />
          <TextField
            label="Gần nhất — từ"
            type="datetime-local"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={toInputDateTime(value.lastSessionFrom)}
            onChange={(e) =>
              onChange({ lastSessionFrom: fromInputDateTime(e.target.value) })
            }
          />
          <TextField
            label="Gần nhất — đến"
            type="datetime-local"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={toInputDateTime(value.lastSessionTo)}
            onChange={(e) =>
              onChange({ lastSessionTo: fromInputDateTime(e.target.value) })
            }
          />
        </div>
      </section>

      <Divider />

      <section>
        <Typography variant="subtitle2" className="mb-1">
          Ngôn ngữ &amp; quốc gia
        </Typography>
        <p className="mb-2 text-xs text-gray-500">
          Ngôn ngữ máy và quốc gia của user (mã 2 chữ). {HINT}
        </p>
        <div className="flex flex-col gap-3">
          <Autocomplete
            multiple
            size="small"
            options={LOCALE_OPTIONS}
            value={(value.languages ?? []).map(
              (code) => LOCALE_OPTIONS.find((l) => l.code === code) ?? { code, label: code },
            )}
            onChange={(_, selected) => onChange({ languages: selected.map((l) => l.code) })}
            isOptionEqualToValue={(a, b) => a.code === b.code}
            getOptionLabel={(l) => l.label}
            renderInput={(params) => <TextField {...params} label="Ngôn ngữ" />}
          />
          <ChipInputField
            label="Quốc gia"
            values={value.countries ?? []}
            onChange={(vals) => onChange({ countries: vals })}
            transform={(raw) => {
              const v = raw.trim().toUpperCase();
              return /^[A-Z]{2}$/.test(v) ? v : null;
            }}
            placeholder="VN, JP, ..."
            helperText="Mã ISO 2 chữ — gõ rồi Enter để thêm, tự viết hoa."
          />
        </div>
      </section>

      <Divider />

      <section>
        <Typography variant="subtitle2" className="mb-1">
          Thiết bị &amp; loại tài khoản
        </Typography>
        <p className="mb-2 text-xs text-gray-500">{HINT}</p>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="mb-1 text-xs font-medium text-gray-600">Thiết bị</p>
            <FormGroup>
              {DEVICE_TYPE_OPTIONS.map((opt) => (
                <FormControlLabel
                  key={opt.value}
                  control={
                    <Checkbox
                      size="small"
                      checked={(value.deviceTypes ?? []).includes(opt.value)}
                      onChange={() =>
                        onChange({ deviceTypes: toggle(value.deviceTypes, opt.value) })
                      }
                    />
                  }
                  label={opt.label}
                />
              ))}
            </FormGroup>
          </div>
          <div>
            <p className="mb-1 text-xs font-medium text-gray-600">Loại tài khoản</p>
            <FormGroup>
              {USER_TYPE_OPTIONS.map((opt) => (
                <FormControlLabel
                  key={opt.value}
                  control={
                    <Checkbox
                      size="small"
                      checked={(value.userTypes ?? []).includes(opt.value)}
                      onChange={() =>
                        onChange({ userTypes: toggle(value.userTypes, opt.value) })
                      }
                    />
                  }
                  label={opt.label}
                />
              ))}
            </FormGroup>
          </div>
        </div>
      </section>

      <Divider />

      <section>
        <Typography variant="subtitle2" className="mb-1">
          Vòng đời (lifecycle)
        </Typography>
        <p className="mb-2 text-xs text-gray-500">
          Số ngày kể từ lần dùng đầu tiên (D0, D1, … D30) — hai đầu đều được tính. {HINT}
        </p>
        <div className="grid grid-cols-2 gap-3">
          <TextField
            label="Từ ngày (D)"
            type="number"
            size="small"
            inputProps={{ min: 0 }}
            value={value.lifecycleFrom ?? ""}
            onChange={(e) =>
              onChange({
                lifecycleFrom: e.target.value === "" ? null : Number(e.target.value),
              })
            }
          />
          <TextField
            label="Đến ngày (D)"
            type="number"
            size="small"
            inputProps={{ min: 0 }}
            value={value.lifecycleTo ?? ""}
            onChange={(e) =>
              onChange({
                lifecycleTo: e.target.value === "" ? null : Number(e.target.value),
              })
            }
            error={
              value.lifecycleFrom != null &&
              value.lifecycleTo != null &&
              value.lifecycleTo < value.lifecycleFrom
            }
            helperText={
              value.lifecycleFrom != null &&
              value.lifecycleTo != null &&
              value.lifecycleTo < value.lifecycleFrom
                ? "Phải ≥ Từ ngày"
                : undefined
            }
          />
        </div>
      </section>

      <Divider />

      <section>
        <Typography variant="subtitle2" className="mb-1">
          User cụ thể
        </Typography>
        <p className="mb-2 text-xs text-gray-500">
          Id user (Mongo ObjectId), mỗi id một dòng. Id không hợp lệ bị bỏ qua khi lưu. {HINT}
        </p>
        <TextField
          multiline
          minRows={3}
          maxRows={8}
          fullWidth
          size="small"
          placeholder={"66f1a2b3c4d5e6f7a8b9c0d1"}
          value={(value.userIds ?? []).join("\n")}
          onChange={(e) => onChange({ userIds: e.target.value.split("\n") })}
        />
      </section>

      <Divider />

      <section>
        <Typography variant="subtitle2" className="mb-1">
          Mục tiêu &amp; chủ đề onboarding
        </Typography>
        <p className="mb-2 text-xs text-gray-500">
          Id câu trả lời "mục tiêu học" và id chủ đề user chọn khi onboarding. {HINT}
        </p>
        <div className="grid grid-cols-2 gap-3">
          <ChipInputField
            label="Mục tiêu học (userGoals)"
            values={(value.userGoals ?? []).map(String)}
            onChange={(vals) => onChange({ userGoals: vals.map(Number) })}
            transform={(raw) => (isInteger(raw) ? raw.trim() : null)}
            placeholder="1, 2, ..."
            helperText="Gõ rồi Enter để thêm."
          />
          <ChipInputField
            label="Chủ đề (topicIds)"
            values={(value.topicIds ?? []).map(String)}
            onChange={(vals) => onChange({ topicIds: vals.map(Number) })}
            transform={(raw) => (isInteger(raw) ? raw.trim() : null)}
            placeholder="3, 5, ..."
            helperText="Gõ rồi Enter để thêm."
          />
        </div>
      </section>
    </div>
  );
};

export default SegmentCriteriaForm;
