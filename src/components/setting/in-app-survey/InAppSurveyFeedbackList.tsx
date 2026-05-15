import { useCallback, useEffect, useState } from "react";
import { Pagination } from "@mui/material";
import { inAppSurveyService } from "../../../services/inAppSurveyService";
import { LangCode } from "../../../types/enum/common.enum";
import {
  IInAppSurveyResponse,
  InAppSurveyResponseListResult,
} from "../../../types/interface/in-app-survey.interface";
import { useNotification } from "../../../utils/hooks/useNotification";
import InAppSurveyResponseCard from "./InAppSurveyResponseCard";
import InAppSurveyUserFilter from "./InAppSurveyUserFilter";

interface Props {
  lang: LangCode;
}
const normalizeResponseList = (payload: any): InAppSurveyResponseListResult => {
  const data = payload?.data ?? payload ?? {};
  const items = Array.isArray(data.items) ? data.items : [];
  return {
    items,
    total: Number(data.total) || items.length,
    totalPages: Number(data.totalPages) || 1,
    currentPage: Number(data.currentPage) || 1,
    itemsPerPage: Number(data.itemsPerPage) || 20,
  };
};
const InAppSurveyFeedbackList = ({ lang }: Props) => {
  const { showError } = useNotification();
  const [items, setItems] = useState<IInAppSurveyResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [take, setTake] = useState(20);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [selectedUserId, setSelectedUserId] = useState("");
  const fetchResponses = useCallback(async () => {
    setLoading(true);
    try {
      const result = await inAppSurveyService.getResponses({
        page,
        take,
        ...(selectedUserId ? { userId: selectedUserId } : {}),
      });
      const normalized = normalizeResponseList(result);
      setItems(normalized.items);
      setTotalPages(normalized.totalPages);
      setTotal(normalized.total);
    } catch (error) {
      console.error("Failed to fetch in-app survey responses", error);
      showError("Không tải được danh sách survey feedback");
      setItems([]);
      setTotalPages(1);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  }, [page, selectedUserId, showError, take]);
  useEffect(() => {
    fetchResponses();
  }, [fetchResponses]);

  const handleUserChange = (userId: string) => {
    setPage(1);
    setSelectedUserId(userId);
  };
  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
        <InAppSurveyUserFilter
          selectedUserId={selectedUserId}
          onChange={handleUserChange}
        />
      </div>
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3">
          <div className="text-sm font-semibold text-slate-900">
            Feedback responses
          </div>
          <div className="text-xs text-slate-500">{total} records</div>
        </div>
        {loading ? (
          <div className="p-8 text-center text-sm text-slate-500">
            Loading responses...
          </div>
        ) : items.length === 0 ? (
          <div className="p-8 text-center text-sm text-slate-500">
            No responses found.
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {items.map((response) => (
              <InAppSurveyResponseCard
                key={response._id}
                response={response}
                lang={lang}
              />
            ))}
          </div>
        )}
      </div>
      <div className="flex flex-col items-center justify-between gap-3 md:flex-row">
        <div className="flex items-center gap-2 text-sm text-slate-600">
          <span>Page size</span>
          <select
            value={take}
            onChange={(event) => {
              setPage(1);
              setTake(Number(event.target.value));
            }}
            className="rounded-lg border border-slate-300 bg-white px-2 py-1 text-sm text-slate-950 outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100"
          >
            {[10, 20, 50].map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
        {totalPages > 1 ? (
          <Pagination
            count={totalPages}
            page={page}
            onChange={(_, nextPage) => setPage(nextPage)}
            color="primary"
          />
        ) : null}
      </div>
    </div>
  );
};

export default InAppSurveyFeedbackList;
