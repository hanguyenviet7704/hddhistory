import React from "react";
import { Chip } from "@mui/material";

import { CommunityContentStatus } from "../../types/interface/community.interface";

const LABELS: Record<
  CommunityContentStatus,
  { text: string; color: "success" | "warning" | "default" }
> = {
  [CommunityContentStatus.VISIBLE]: { text: "Đang hiện", color: "success" },
  [CommunityContentStatus.HIDDEN]: { text: "Đã ẩn", color: "warning" },
  // The author removed it themselves — nothing for a moderator to do, but the
  // row still matters when a report points at it.
  [CommunityContentStatus.DELETED]: { text: "Tác giả đã xoá", color: "default" },
};

const CommunityStatusChip: React.FC<{ status: CommunityContentStatus }> = ({
  status,
}) => {
  const meta = LABELS[status] ?? LABELS[CommunityContentStatus.VISIBLE];
  return <Chip size="small" label={meta.text} color={meta.color} />;
};

export default CommunityStatusChip;
