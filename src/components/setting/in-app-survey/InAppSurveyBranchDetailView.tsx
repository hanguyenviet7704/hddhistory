import { useCallback, useEffect, useState } from "react";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";
import { Pagination } from "@mui/material";
import { inAppSurveyService } from "../../../services/inAppSurveyService";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyBranchResponsesResult,
  InAppSurveyBranchSummary,
} from "../../../types/interface/in-app-survey.interface";
import { useNotification } from "../../../utils/hooks/useNotification";
import InAppSurveyEmojiImage from "./InAppSurveyEmojiImage";
import {
  DatePreset,
  buildDateRangeParams,
  formatDateTime,
  formatNumber,
  getBranchLabel,
  getPlainTranslationValue,
} from "./in-app-survey-analytics-utils";

interface Props {
  branch: InAppSurveyBranchSummary;
  lang: LangCode;
  preset: DatePreset;
  customStart: string;
  customEnd: string;
  onBack: () => void;
}

const InAppSurveyBranchDetailView = ({
  branch,
  lang,
  preset,
  customStart,
  customEnd,
  onBack,
}: Props) => {
  const { showError } = useNotification();
  const [data, setData] = useState<InAppSurveyBranchResponsesResult | null>(
    null,
  );
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [optionId, setOptionId] = useState("");

  const fetchData = useCallback(async () => {
    try {
      const range = buildDateRangeParams(preset, customStart, customEnd);
      const result = await inAppSurveyService.getBranchResponses(
        branch.branchId,
        { ...range, page, take: 10, search, optionId, order: "desc" },
      );
      setData(result);
    } catch (error) {
      console.error("Failed to fetch branch responses", error);
      showError("Không tải được phản hồi của branch");
    }
  }, [branch.branchId, customEnd, customStart, optionId, page, preset, search, showError]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return (
    <div className="space-y-5">
      <button
        type="button"
        onClick={onBack}
        className="inline-flex items-center gap-2 text-sm font-semibold text-slate-500"
      >
        <ArrowLeftIcon className="h-4 w-4" />
        Back to overview
      </button>
      <div className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3">
          <InAppSurveyEmojiImage
            emoji={branch.emoji}
            label={branch.branchName}
            score={branch.ratingScore}
            className="h-9 w-9"
          />
          <h3 className="text-xl font-bold text-slate-950">
            {getBranchLabel(branch.ratingScore, branch.branchName)} branch
          </h3>
        </div>
        <div className="text-sm text-slate-500">
          <b className="text-xl text-slate-950">{formatNumber(data?.total)}</b>{" "}
          responses · {branch.percent}% of total
        </div>
      </div>
      <div>
        <input
          value={search}
          onChange={(event) => {
            setPage(1);
            setSearch(event.target.value);
          }}
          placeholder="Search responses..."
          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-indigo-300"
        />
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-sm font-semibold text-slate-500">
          Filter by Q2:
        </span>
        {(data?.optionFilters || []).map((item) => (
          <button
            type="button"
            key={item.option.id}
            onClick={() => {
              setPage(1);
              setOptionId(optionId === item.option.id ? "" : item.option.id);
            }}
            className={`rounded-full border px-3 py-1 text-sm ${
              optionId === item.option.id
                ? "border-indigo-500 bg-indigo-50 text-indigo-700"
                : "border-slate-200 bg-white text-slate-600"
            }`}
          >
            {getPlainTranslationValue(item.option.value, lang)} · {item.count}
          </button>
        ))}
      </div>
      <div className="space-y-3">
        {(data?.items || []).map((item) => (
          <div
            key={item._id}
            className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="text-sm text-slate-400">
              {formatDateTime(item.submittedAt || item.createdAt)}
            </div>
            <div className="mt-4 flex flex-wrap items-center gap-2">
              <span className="text-xs font-semibold text-slate-400">Q2:</span>
              {item.selectedOptions.map((option) => (
                <span
                  key={option.id}
                  className="rounded-full bg-indigo-50 px-3 py-1 text-sm font-semibold text-indigo-600"
                >
                  {getPlainTranslationValue(option.value, lang)}
                </span>
              ))}
            </div>
            <p className="mt-4 text-base leading-7 text-slate-950">
              "{item.feedback || "-"}"
            </p>
          </div>
        ))}
      </div>
      {(data?.totalPages || 1) > 1 ? (
        <Pagination
          count={data?.totalPages || 1}
          page={page}
          onChange={(_, nextPage) => setPage(nextPage)}
          color="primary"
        />
      ) : null}
    </div>
  );
};

export default InAppSurveyBranchDetailView;
