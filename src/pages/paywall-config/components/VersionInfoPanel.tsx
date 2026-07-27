import React from "react";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import { PaywallEnvironment } from "../../../types/enum/paywall-config.enum";
import { PaywallConfigVersion } from "../../../types/interface/paywall-config.interface";
import { formatDateTime } from "../paywallConfigFormat";

interface VersionInfoPanelProps {
  environment: PaywallEnvironment;
  source: "conditional" | "default";
  version?: PaywallConfigVersion;
}

const sourceCaption: Record<PaywallEnvironment, Record<"conditional" | "default", string>> = {
  [PaywallEnvironment.DEV]: {
    conditional: "A dev-specific override is published - dev reads this value, not prod's.",
    default: "No dev override published yet - dev is inheriting the prod value.",
  },
  [PaywallEnvironment.PROD]: {
    default: "This is the value every production client reads.",
    conditional: "This is the value every production client reads.",
  },
};

const VersionInfoPanel: React.FC<VersionInfoPanelProps> = ({
  environment,
  source,
  version,
}) => {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 flex flex-wrap items-center gap-x-6 gap-y-1.5 text-xs text-slate-600">
      <span className="inline-flex items-center gap-1.5 font-medium text-slate-700">
        <InformationCircleIcon className="h-4 w-4 text-slate-400" />
        Remote Config
      </span>
      <span>
        Version <span className="font-semibold text-slate-800">{version?.versionNumber ?? "-"}</span>
      </span>
      <span>
        Updated <span className="font-medium text-slate-800">{formatDateTime(version?.updateTime)}</span>
      </span>
      <span>
        By{" "}
        <span className="font-medium text-slate-800">
          {version?.updateUser?.name || version?.updateUser?.email || "Unknown"}
        </span>
      </span>
      <span
        className={`inline-flex items-center px-2 py-0.5 rounded-full font-medium ${
          source === "conditional"
            ? "bg-sky-50 text-sky-700 border border-sky-100"
            : "bg-slate-100 text-slate-700 border border-slate-200"
        }`}
        title={sourceCaption[environment][source]}
      >
        {source}
      </span>
      <span className="text-slate-400">{sourceCaption[environment][source]}</span>
    </div>
  );
};

export default VersionInfoPanel;
