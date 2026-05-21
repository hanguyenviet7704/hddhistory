import { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import { inAppSurveyService } from "../../../services/inAppSurveyService";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyUserResponsesResult,
} from "../../../types/interface/in-app-survey.interface";
import { useNotification } from "../../../utils/hooks/useNotification";
import InAppSurveyEmojiImage from "./InAppSurveyEmojiImage";
import InAppSurveyUserResponseCard from "./InAppSurveyUserResponseCard";
import {
  DatePreset,
  buildDateRangeParams,
  formatNumber,
  getBranchLabel,
} from "./in-app-survey-analytics-utils";

interface Props {
  lang: LangCode;
  preset: DatePreset;
  customStart: string;
  customEnd: string;
}

const InAppSurveyByUserView = ({
  lang,
  preset,
  customStart,
  customEnd,
}: Props) => {
  const { showError } = useNotification();
  const [data, setData] = useState<InAppSurveyUserResponsesResult | null>(null);
  const [page, setPage] = useState(1);
  const [take, setTake] = useState(10);
  const [search, setSearch] = useState("");
  const [branchId, setBranchId] = useState("");

  const fetchData = useCallback(async () => {
    try {
      const result = await inAppSurveyService.getUserResponses({
        ...buildDateRangeParams(preset, customStart, customEnd),
        page,
        take,
        search,
        branchId,
        order: "desc",
      });
      setData(result);
    } catch (error) {
      console.error("Failed to fetch user survey responses", error);
      showError("Không tải được survey theo user");
    }
  }, [branchId, customEnd, customStart, page, preset, search, showError, take]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <span className="text-2xl font-bold text-slate-950">
          {formatNumber(data?.distinctUsers)}
        </span>{" "}
        <span className="text-slate-500">users responded</span>
      </div>
      <input
        value={search}
        onChange={(event) => {
          setPage(1);
          setSearch(event.target.value);
        }}
        placeholder="Search responses..."
        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-indigo-300"
      />
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-sm font-semibold text-slate-500">
          Filter by branch:
        </span>
        {(data?.branchFilters || []).map((item) => (
          <button
            key={item.branchId}
            type="button"
            onClick={() => {
              setPage(1);
              setBranchId(branchId === item.branchId ? "" : item.branchId);
            }}
            className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-sm ${
              branchId === item.branchId
                ? "border-indigo-500 bg-indigo-50 text-indigo-700"
                : "border-slate-200 bg-white text-slate-600"
            }`}
          >
            <InAppSurveyEmojiImage
              emoji={item.emoji}
              label={item.branchName}
              score={item.ratingScore}
              className="h-5 w-5"
            />
            {getBranchLabel(item.ratingScore, item.branchName)} · {item.count}
          </button>
        ))}
      </div>
      <div className="space-y-4">
        {(data?.items || []).map((response) => (
          <InAppSurveyUserResponseCard
            key={response._id}
            response={response}
            lang={lang}
          />
        ))}
      </div>
      <div className="flex flex-col items-center justify-between gap-3 md:flex-row">
        <select
          value={take}
          onChange={(event) => {
            setPage(1);
            setTake(Number(event.target.value));
          }}
          className="rounded-lg border border-slate-300 bg-white px-2 py-1 text-sm"
        >
          {[10, 20, 50].map((option) => (
            <option key={option} value={option}>
              {option} per page
            </option>
          ))}
        </select>
        {(data?.totalPages || 1) > 1 ? (
          <Pagination
            count={data?.totalPages || 1}
            page={page}
            onChange={(_, nextPage) => setPage(nextPage)}
            color="primary"
          />
        ) : null}
      </div>
    </div>
  );
};

export default InAppSurveyByUserView;
