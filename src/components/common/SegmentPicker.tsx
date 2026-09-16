import { Autocomplete, TextField } from "@mui/material";

import { SegmentOption } from "../../types/interface/segment.interface";

interface Props {
  /** The full segment catalogue, loaded once by the page. */
  segments: SegmentOption[];
  /** Currently selected segment ids. */
  value: string[];
  onChange: (segmentIds: string[]) => void;
  label?: string;
  helperText?: string;
}

/**
 * Audience picker, shared by every surface that targets by segment.
 *
 * Extracted from the Home banner slide card so the two places that ask this
 * question ask it the same way — the same wording matters as much as the same
 * control: "bỏ trống = mọi người" is the rule an editor has to trust, and it
 * should not be phrased differently on two screens.
 *
 * An id with no matching segment still renders (as its raw id) rather than
 * vanishing from the field: a deleted segment only widens targeting on the
 * server, and silently dropping it here would hide that from the editor.
 */
export default function SegmentPicker({
  segments,
  value,
  onChange,
  label = "Chỉ hiện với các phân khúc user",
  helperText = "Bỏ trống = mọi người dùng. Khớp BẤT KỲ phân khúc nào được chọn.",
}: Props) {
  return (
    <Autocomplete
      multiple
      size="small"
      options={segments}
      value={value.map(
        (id) => segments.find((s) => s._id === id) ?? { _id: id, name: id },
      )}
      onChange={(_, selected) => onChange(selected.map((s) => s._id))}
      isOptionEqualToValue={(a, b) => a._id === b._id}
      getOptionLabel={(s) => s.name}
      renderInput={(params) => (
        <TextField {...params} label={label} helperText={helperText} />
      )}
    />
  );
}
