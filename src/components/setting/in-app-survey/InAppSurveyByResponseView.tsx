import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyBranchSummary,
  InAppSurveyStatisticsOverview,
} from "../../../types/interface/in-app-survey.interface";
import InAppSurveyEmojiImage from "./InAppSurveyEmojiImage";
import InAppSurveyMetricCard from "./InAppSurveyMetricCard";
import {
  formatDateTime,
  formatNumber,
  getBranchLabel,
  getPlainTranslationValue,
  getQuestionText,
} from "./in-app-survey-analytics-utils";

interface Props {
  data: InAppSurveyStatisticsOverview;
  lang: LangCode;
  onViewBranch: (branch: InAppSurveyBranchSummary) => void;
}

const ratingColors = [
  "bg-red-600",
  "bg-orange-600",
  "bg-amber-600",
  "bg-emerald-600",
  "bg-green-700",
];

const InAppSurveyByResponseView = ({ data, lang, onViewBranch }: Props) => {
  if (!data?.metrics) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
        No survey statistics found.
      </div>
    );
  }

  return (
    <div className="space-y-6">
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
      <InAppSurveyMetricCard
        label="Total responses"
        value={data.metrics.totalResponses.value}
        delta={data.metrics.totalResponses.delta}
      />
      <InAppSurveyMetricCard
        label="Average rating"
        value={data.metrics.averageRating.value}
        denominator="5"
        delta={data.metrics.averageRating.delta}
        deltaSuffix=""
      />
      <InAppSurveyMetricCard
        label="Completion rate"
        value={data.metrics.completionRate.value}
        suffix="%"
        delta={data.metrics.completionRate.delta}
      />
      <InAppSurveyMetricCard
        label="Response rate"
        value={data.metrics.responseRate.value}
        suffix="%"
        delta={data.metrics.responseRate.delta}
      />
    </div>

    <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="mb-6 flex items-center justify-between border-b border-slate-100 pb-4">
        <h3 className="text-base font-bold uppercase tracking-wide text-slate-900">
          Q1 — Rating distribution
        </h3>
        <span className="text-sm text-slate-400">
          {formatNumber(data.metrics.totalResponses.value)} responses
        </span>
      </div>
      <div className="space-y-4">
        {data.ratingDistribution.map((item, index) => (
          <div
            key={item.branchId}
            className="grid grid-cols-[48px_120px_1fr_110px] items-center gap-4"
          >
            <InAppSurveyEmojiImage
              emoji={item.emoji}
              label={item.branchName}
              score={item.ratingScore}
              className="h-8 w-8"
            />
            <span className="text-sm font-medium text-slate-600">
              {getBranchLabel(item.ratingScore, item.branchName, "Level")}
            </span>
            <ProgressBar
              percent={item.percent}
              className={ratingColors[index] || "bg-indigo-600"}
            />
            <span className="text-right text-sm text-slate-500">
              <b className="text-slate-900">{formatNumber(item.count)}</b> ·{" "}
              {item.percent}%
            </span>
          </div>
        ))}
      </div>
    </section>

    {(data.branches || []).map((branch) => (
      <BranchSummaryCard
        key={branch.branchId}
        branch={branch}
        lang={lang}
        total={data.metrics.totalResponses.value}
        onViewBranch={onViewBranch}
      />
    ))}
  </div>
  );
};

const BranchSummaryCard = ({
  branch,
  lang,
  total,
  onViewBranch,
}: {
  branch: InAppSurveyBranchSummary;
  lang: LangCode;
  total: number;
  onViewBranch: (branch: InAppSurveyBranchSummary) => void;
}) => (
  <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 pb-4">
      <div className="flex items-center gap-3">
        <InAppSurveyEmojiImage
          emoji={branch.emoji}
          label={branch.branchName}
          score={branch.ratingScore}
          className="h-8 w-8"
        />
        <h3 className="text-lg font-bold text-slate-950">
          Branch {branch.ratingScore} —{" "}
          {getBranchLabel(branch.ratingScore, branch.branchName)}
        </h3>
      </div>
      <div className="text-sm text-slate-500">
        <b className="text-lg text-slate-950">{formatNumber(branch.count)}</b>{" "}
        responses · {total ? branch.percent : 0}% of total
      </div>
    </div>
    <div className="grid grid-cols-1 gap-8 pt-5 xl:grid-cols-2">
      <div>
        <h4 className="text-sm font-bold uppercase tracking-wide text-slate-400">
          Q2 · "{getQuestionText(branch.closedQuestion, lang)}"
        </h4>
        <div className="mt-4 space-y-4">
          {branch.options.map((item) => (
            <div key={item.option.id} className="space-y-2">
              <div className="flex items-center justify-between gap-3">
                <span className="text-sm font-medium text-slate-900">
                  {getPlainTranslationValue(item.option.value, lang)}
                </span>
                <span className="text-sm text-slate-500">
                  {formatNumber(item.count)} · {item.percent}%
                </span>
              </div>
              <ProgressBar percent={item.percent} className="bg-indigo-600" />
            </div>
          ))}
        </div>
      </div>
      <div>
        <h4 className="text-sm font-bold uppercase tracking-wide text-slate-400">
          Q3 · "{getQuestionText(branch.openQuestion, lang)}"
        </h4>
        <div className="mt-4 max-h-72 space-y-5 overflow-auto pr-2">
          {branch.feedbacks.slice(0, 7).map((item) => (
            <div key={item._id}>
              <div className="text-xs text-slate-400">
                {formatDateTime(item.submittedAt)}
              </div>
              <p className="mt-2 text-sm leading-6 text-slate-900">
                "{item.feedback}"
              </p>
            </div>
          ))}
        </div>
        <button
          type="button"
          onClick={() => onViewBranch(branch)}
          className="mt-4 text-sm font-semibold text-indigo-600"
        >
          View all {formatNumber(branch.count)} responses →
        </button>
      </div>
    </div>
  </section>
);

const ProgressBar = ({
  percent,
  className,
}: {
  percent: number;
  className: string;
}) => (
  <div className="h-2 rounded-full bg-stone-100">
    <div
      className={`h-2 rounded-full ${className}`}
      style={{ width: `${Math.min(Math.max(percent, 0), 100)}%` }}
    />
  </div>
);

export default InAppSurveyByResponseView;
