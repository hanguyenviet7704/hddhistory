import { useCallback, useEffect, useMemo, useState } from "react";
import { inAppSurveyService } from "../../../services/inAppSurveyService";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyBranchSummary,
  InAppSurveyStatisticsOverview,
} from "../../../types/interface/in-app-survey.interface";
import { useNotification } from "../../../utils/hooks/useNotification";
import InAppSurveyAnalyticsHeader from "./InAppSurveyAnalyticsHeader";
import InAppSurveyBranchDetailView from "./InAppSurveyBranchDetailView";
import InAppSurveyByResponseView from "./InAppSurveyByResponseView";
import InAppSurveyByUserView from "./InAppSurveyByUserView";
import {
  DatePreset,
  SurveyTab,
  buildDateRangeParams,
  downloadSurveyXlsx,
} from "./in-app-survey-analytics-utils";

interface Props {
  lang: LangCode;
}

const todayInput = () => new Date().toISOString().slice(0, 10);

const InAppSurveyFeedbackList = ({ lang }: Props) => {
  const { showError, showSuccess } = useNotification();
  const [activeTab, setActiveTab] = useState<SurveyTab>("byResponse");
  const [preset, setPreset] = useState<DatePreset>("30");
  const [customStart, setCustomStart] = useState("");
  const [customEnd, setCustomEnd] = useState(todayInput());
  const [overview, setOverview] = useState<InAppSurveyStatisticsOverview | null>(
    null,
  );
  const [loading, setLoading] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [confirmDownloadOpen, setConfirmDownloadOpen] = useState(false);
  const [selectedBranch, setSelectedBranch] =
    useState<InAppSurveyBranchSummary | null>(null);

  const rangeParams = useMemo(
    () => buildDateRangeParams(preset, customStart, customEnd),
    [customEnd, customStart, preset],
  );

  const fetchOverview = useCallback(async () => {
    try {
      setLoading(true);
      const result = await inAppSurveyService.getStatisticsOverview(rangeParams);
      setOverview(result);
    } catch (error) {
      console.error("Failed to fetch survey statistics", error);
      showError("Không tải được thống kê survey");
    } finally {
      setLoading(false);
    }
  }, [rangeParams, showError]);

  useEffect(() => {
    fetchOverview();
  }, [fetchOverview]);

  const handleExport = async () => {
    try {
      setConfirmDownloadOpen(false);
      setExporting(true);
      const file = await inAppSurveyService.exportResponses({
        ...rangeParams,
        lang,
      });
      downloadSurveyXlsx(file);
      showSuccess("Export survey thành công");
    } catch (error) {
      console.error("Failed to export survey", error);
      showError("Export survey thất bại");
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="space-y-6">
      {!selectedBranch ? (
        <InAppSurveyAnalyticsHeader
          activeTab={activeTab}
          preset={preset}
          customStart={customStart}
          customEnd={customEnd}
          exporting={exporting}
          onTabChange={setActiveTab}
          onPresetChange={(nextPreset) => {
            setSelectedBranch(null);
            setPreset(nextPreset);
          }}
          onCustomStartChange={setCustomStart}
          onCustomEndChange={setCustomEnd}
          onExport={() => setConfirmDownloadOpen(true)}
        />
      ) : null}

      {confirmDownloadOpen ? (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60">
          <div className="w-[90%] max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="mb-3 text-xl font-semibold text-gray-800">
              Confirm download
            </h2>
            <p className="mb-6 text-gray-600">
              Are you sure you want to download the in-app survey export file?
            </p>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setConfirmDownloadOpen(false)}
                className="rounded-lg bg-gray-200 px-4 py-2 text-gray-700 transition hover:bg-gray-300"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleExport}
                className="rounded-lg bg-blue-600 px-4 py-2 text-white transition hover:bg-blue-700"
              >
                Download
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {selectedBranch ? (
        <InAppSurveyBranchDetailView
          branch={selectedBranch}
          lang={lang}
          preset={preset}
          customStart={customStart}
          customEnd={customEnd}
          onBack={() => setSelectedBranch(null)}
        />
      ) : loading ? (
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          Loading survey statistics...
        </div>
      ) : activeTab === "byResponse" && overview ? (
        <InAppSurveyByResponseView
          data={overview}
          lang={lang}
          onViewBranch={setSelectedBranch}
        />
      ) : activeTab === "byUser" ? (
        <InAppSurveyByUserView
          lang={lang}
          preset={preset}
          customStart={customStart}
          customEnd={customEnd}
        />
      ) : (
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          No survey data found.
        </div>
      )}
    </div>
  );
};

export default InAppSurveyFeedbackList;
