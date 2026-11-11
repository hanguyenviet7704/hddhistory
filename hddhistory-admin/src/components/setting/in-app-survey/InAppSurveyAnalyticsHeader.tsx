import {
  ArrowDownTrayIcon,
  ChatBubbleLeftRightIcon,
  UserIcon,
} from "@heroicons/react/24/outline";
import { DatePreset, SurveyTab } from "./in-app-survey-analytics-utils";

interface Props {
  activeTab: SurveyTab;
  preset: DatePreset;
  customStart: string;
  customEnd: string;
  exporting: boolean;
  onTabChange: (tab: SurveyTab) => void;
  onPresetChange: (preset: DatePreset) => void;
  onCustomStartChange: (value: string) => void;
  onCustomEndChange: (value: string) => void;
  onExport: () => void;
}

const InAppSurveyAnalyticsHeader = ({
  activeTab,
  preset,
  customStart,
  customEnd,
  exporting,
  onTabChange,
  onPresetChange,
  onCustomStartChange,
  onCustomEndChange,
  onExport,
}: Props) => (
  <div className="flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
    <div className="flex flex-wrap items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2 shadow-sm">
      <span className="text-sm text-slate-500">Date range:</span>
      <select
        value={preset}
        onChange={(event) => onPresetChange(event.target.value as DatePreset)}
        className="rounded-lg border-0 bg-transparent text-sm font-semibold text-slate-900 outline-none"
      >
        <option value="30">Last 30 days</option>
        <option value="60">Last 60 days</option>
        <option value="custom">Custom</option>
      </select>
      {preset === "custom" ? (
        <>
          <input
            type="date"
            value={customStart}
            onChange={(event) => onCustomStartChange(event.target.value)}
            className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
          />
          <input
            type="date"
            value={customEnd}
            onChange={(event) => onCustomEndChange(event.target.value)}
            className="rounded-lg border border-slate-200 px-2 py-1 text-sm"
          />
        </>
      ) : null}
    </div>

    <div className="flex flex-wrap items-center gap-3">
      <div className="flex rounded-2xl bg-stone-100 p-1">
        <button
          type="button"
          onClick={() => onTabChange("byResponse")}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold ${
            activeTab === "byResponse"
              ? "bg-white text-slate-950 shadow-sm"
              : "text-slate-500"
          }`}
        >
          <ChatBubbleLeftRightIcon className="h-4 w-4" />
          By response
        </button>
        <button
          type="button"
          onClick={() => onTabChange("byUser")}
          className={`inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold ${
            activeTab === "byUser"
              ? "bg-white text-slate-950 shadow-sm"
              : "text-slate-500"
          }`}
        >
          <UserIcon className="h-4 w-4" />
          By user
        </button>
      </div>
      <button
        type="button"
        onClick={onExport}
        disabled={exporting}
        className="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-900 shadow-sm disabled:opacity-60"
      >
        <ArrowDownTrayIcon className="h-4 w-4" />
        {exporting ? "Exporting..." : "Export data"}
      </button>
    </div>
  </div>
);

export default InAppSurveyAnalyticsHeader;
