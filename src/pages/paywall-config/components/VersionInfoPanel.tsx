import React from "react";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
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
const VersionInfoPanel: React.FC<VersionInfoPanelProps> = ({
  version,
  publishedAt,
  publishedBy,
}) => {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 flex flex-wrap items-center gap-x-6 gap-y-1.5 text-xs text-slate-600">
      <span className="inline-flex items-center gap-1.5 font-medium text-slate-700">
        <InformationCircleIcon className="h-4 w-4 text-slate-400" />
        Live version
      </span>
      <span>
        Version <span className="font-semibold text-slate-800">{version}</span>
      </span>
      <span>
        Published{" "}
        <span className="font-medium text-slate-800">{formatDateTime(publishedAt)}</span>
      </span>
      <span>
        By <span className="font-medium text-slate-800">{publishedBy || "Unknown"}</span>
      </span>
    </div>
  );
};

export default VersionInfoPanel;
