import React from "react";
import { Chip } from "@mui/material";

import { SegmentCriteria } from "../../types/interface/segment.interface";
import { summarizeCriteria } from "./segmentCriteria.utils";

interface Props {
  criteria?: SegmentCriteria | null;
}

/** Compact chip row for the segments table — see `summarizeCriteria`. */
const SegmentCriteriaSummary: React.FC<Props> = ({ criteria }) => {
  const chips = summarizeCriteria(criteria);

  if (chips.length === 0) {
    return <Chip size="small" variant="outlined" label="Mọi user (không lọc)" />;
  }

  return (
    <div className="flex flex-wrap gap-1">
      {chips.map((label) => (
        <Chip key={label} size="small" variant="outlined" label={label} />
      ))}
    </div>
  );
};

export default SegmentCriteriaSummary;
