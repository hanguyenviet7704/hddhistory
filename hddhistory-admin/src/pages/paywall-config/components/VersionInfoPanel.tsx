import React from "react";
import { PaywallConfigResponse } from "../../../types/interface/paywall-config.interface";
import { formatDateTime } from "../paywallConfigFormat";

interface VersionInfoPanelProps {
  version: PaywallConfigResponse["version"];
  publishedAt: PaywallConfigResponse["publishedAt"];
  publishedBy?: PaywallConfigResponse["publishedBy"];
}

// Flat replacement for the old Remote Config `template.version` object --
// MySQL tracks version/publishedAt/publishedBy directly on the row, and
// there is no more "conditional vs default" / dev-inheriting-prod notion:
// this deployment's database only ever holds its own history.
//
// Styled as a status strip (dot + label reads as state, not as a sentence)
// so the operator can tell at a glance "this is what's live right now".
const VersionInfoPanel: React.FC<VersionInfoPanelProps> = ({
  version,
  publishedAt,
  publishedBy,
}) => {
  return (
    <div className="rounded-xl border border-slate-200 border-l-4 border-l-emerald-500 bg-white px-4 py-2.5 flex flex-wrap items-center gap-x-5 gap-y-1 text-xs text-slate-600 shadow-sm">
      <span className="inline-flex items-center gap-1.5">
        <span className="h-2 w-2 rounded-full bg-emerald-500" aria-hidden="true" />
        <span className="font-semibold uppercase tracking-wide text-[11px] text-emerald-700">
          Bản đang chạy
        </span>
      </span>
      <span>
        Phiên bản <span className="font-semibold text-slate-800">{version}</span>
      </span>
      <span>
        Đăng lúc{" "}
        <span className="font-medium text-slate-800">{formatDateTime(publishedAt)}</span>
      </span>
      <span>
        Bởi <span className="font-medium text-slate-800">{publishedBy || "Không rõ"}</span>
      </span>
    </div>
  );
};

export default VersionInfoPanel;
