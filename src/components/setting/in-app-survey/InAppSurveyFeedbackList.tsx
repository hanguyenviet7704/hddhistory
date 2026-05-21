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
  downloadSurveyCsv,
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
      setExporting(true);
      const rows = await inAppSurveyService.exportResponses({
        ...rangeParams,
        lang,
      });
      downloadSurveyCsv(rows);
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
          onExport={handleExport}
        />
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
